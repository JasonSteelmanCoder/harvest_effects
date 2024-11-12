WITH filtered_plot_observations AS (
	WITH filtered_plots AS (
		WITH flagged_plots AS (
			WITH flagged_plot_observations AS (
				WITH flagged_conditions AS (
					WITH plot_observations AS (
						WITH multi_obs_plots AS (
							WITH RECURSIVE plot_cte AS (
								-- grab multiobserved plots with all of their aliases and years		
								SELECT 
									cn AS original_cn,
									array[cn]::bigint[] AS cn_sequence,
									array[invyr]::bigint[] AS invyr_sequence,
									array[measyear]::bigint[] AS measyear_sequence
								FROM east_us_plot
								WHERE prev_plt_cn IS NULL
								
								UNION ALL
							
								SELECT 
									plot_cte.original_cn,
									plot_cte.cn_sequence || east_us_plot.cn,
									plot_cte.invyr_sequence || east_us_plot.invyr,
									plot_cte.measyear_sequence || east_us_plot.measyear
								FROM plot_cte
								JOIN east_us_plot
								ON east_us_plot.prev_plt_cn = plot_cte.cn_sequence[ARRAY_LENGTH(plot_cte.cn_sequence, 1)]
									
							), obs_nums AS (
								SELECT 
									original_cn, 
									MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
								FROM plot_cte
								GROUP BY original_cn
							)
							SELECT 
								plot_cte.original_cn, 
								plot_cte.cn_sequence,
								plot_cte.invyr_sequence,
								plot_cte.measyear_sequence
							FROM plot_cte
							JOIN obs_nums
							ON 
								plot_cte.original_cn = obs_nums.original_cn
								AND ARRAY_LENGTH(plot_cte.cn_sequence, 1) = obs_nums.num
							WHERE num > 2 			-- the plot needs to have been observed at least three times
							ORDER BY num DESC
						)
						-- unnest the individual plots into plot observations
						SELECT 
							original_cn,
							UNNEST(cn_sequence) AS current_cn,
							UNNEST(invyr_sequence) AS invyr,
							UNNEST(measyear_sequence) AS measyear
						FROM multi_obs_plots mop
					)
					-- join plot observations with conditions
					-- Remember: there can be more than one condition per plot observation!
					-- each line of this cte is a *condition*. there is more than one row for each plot observation.
					SELECT 
						original_cn,
						current_cn, 
						po.invyr,
						measyear,
						stdorgcd,
						cond_status_cd,
						presnfcd,
						CASE 
							WHEN trtcd1 IS NULL 
							THEN NULL 
							WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) 
							THEN 10 
							ELSE 0 
						END AS harvested,
						CASE 
							WHEN stdorgcd = 1			-- reject plots that have conditions with artificial regeneration
							THEN 1
							WHEN 
								stdorgcd IS NULL 
								AND cond_status_cd != 1 		-- reject plots that have conditions with null stdorgcd and non-forest cond_status_cd
							THEN 1
							ELSE 0
						END AS reject_this_plot		-- 1 means this plot should be excluded
					FROM plot_observations po
					JOIN east_us_cond euc
					ON po.current_cn = euc.plt_cn
				)
				-- group back into plot observations, aggregating rejection flags into one flag and harvest codes into one code
				SELECT 
					original_cn,
					current_cn,
					invyr,
					measyear,
					ARRAY_AGG(reject_this_plot) AS rejection_flags,
					MAX(reject_this_plot) AS reject_this_plot,
					ARRAY_AGG(harvested) AS harvested_flags,
					MAX(harvested) AS harvested
				FROM flagged_conditions
				GROUP BY 
					original_cn,
					current_cn,
					invyr,
					measyear
			)
			-- group back into unique plots, making aliases, years, and harvest flags into arrays
			-- turn rejection flags from all the observations into one reject_this_plot flag for the whole plot
			SELECT 
				original_cn,
				ARRAY_AGG(current_cn ORDER BY invyr) AS cn_sequence,
				ARRAY_AGG(invyr ORDER BY invyr) AS invyr_sequence,
				ARRAY_AGG(measyear ORDER BY invyr) AS measyear_sequence, 
				ARRAY_AGG(harvested ORDER BY invyr) AS harvested_sequence,
				ARRAY_AGG(reject_this_plot ORDER BY invyr) AS rejection_flags,
				MAX(reject_this_plot) AS reject_this_plot
			FROM flagged_plot_observations
			GROUP BY original_cn
		)
		-- filter out plots that are flagged
		SELECT
			original_cn,
			cn_sequence,
			invyr_sequence,
			measyear_sequence,
			harvested_sequence,
			reject_this_plot
		FROM flagged_plots
		WHERE 
			reject_this_plot = 0
	)
	-- unnest again to get plot observations (this time only from filtered plots)
	SELECT 
		fp.original_cn AS original_plot_cn,
		UNNEST(fp.cn_sequence) AS current_plot_cn,
		UNNEST(fp.invyr_sequence) AS invyr,
		UNNEST(fp.measyear_sequence) AS measyear,
		UNNEST(fp.harvested_sequence) AS harvested
	FROM filtered_plots fp


), multi_obs_trees AS (

	WITH multi_obs_tree_observations AS (
		-- grab all of the observations of trees that were observed at least three times
		SELECT 
			eumot.original_cn,
			UNNEST(eumot.cn_sequence) AS current_cn
		FROM east_us_multi_observed_trees_from_tree_table eumot			
		WHERE ARRAY_LENGTH(eumot.cn_sequence, 1) > 2		-- accept only trees that were observed at least 3x
	)
	-- add a plt_cn column from the east_us_tree table
	SELECT
		moto.original_cn AS original_tree_cn,
		moto.current_cn AS current_tree_cn,
		eut.plt_cn,
		eut.dia,
		rs.association
	FROM multi_obs_tree_observations moto
	JOIN east_us_tree eut
	ON moto.current_cn = eut.cn
	JOIN ref_species rs
	ON rs.spcd = eut.spcd
	WHERE 
		eut.dia IS NOT NULL		-- tree observations must have a valid diameter
		AND eut.statuscd = 1		-- trees must be alive at the time of their observations

), tree_observations AS (

	-- join plot observations with the tree observations that happened there
	-- this filters out trees that are on rejected plots
	-- each row in this cte is a *tree observation* with original_plot_cn referring to the first time that that plot was observed
	SELECT 
		fpo.measyear,
		fpo.harvested,
		mot.original_tree_cn,
		mot.current_tree_cn,
		mot.dia,
		mot.association,
		fpo.original_plot_cn,
		fpo.current_plot_cn
	FROM filtered_plot_observations fpo
	JOIN multi_obs_trees mot
	ON fpo.current_plot_cn = mot.plt_cn

), unique_trees AS (

	-- group the tree observations back into unique trees
	SELECT 
		tobs.original_tree_cn AS original_cn,
		ARRAY_AGG(tobs.current_tree_cn ORDER BY measyear) AS cn_sequence,
		ARRAY_AGG(tobs.current_plot_cn ORDER BY measyear) AS plt_cn,
		tobs.association,
		ARRAY_AGG(tobs.dia ORDER BY measyear) AS dia,
		ARRAY_AGG(tobs.measyear ORDER BY measyear) AS measyear,
		ARRAY_AGG(tobs.harvested ORDER BY measyear) AS harvested
	FROM tree_observations tobs
	GROUP BY
		tobs.original_tree_cn,
		tobs.association

)
-- filter the unique trees for their harvest sequence
SELECT 
	*
FROM unique_trees
WHERE 
	ARRAY_TO_STRING(harvested, ',', 'null') ~ '^(0,)+10(\S)+$'		-- the harvest sequence has any number of zeros, followed by a ten, then other values. In other words, it's not harvested in the first observation (or the first few), but it's harvested before the last observation.





