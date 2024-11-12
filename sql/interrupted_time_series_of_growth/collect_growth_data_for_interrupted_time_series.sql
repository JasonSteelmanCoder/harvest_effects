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
							WHEN stdorgcd = 1			-- reject plots with artificial regeneration
							THEN 1
							WHEN 
								stdorgcd IS NULL 
								AND cond_status_cd = 2 
								AND presnfcd NOT IN (40, 41, 42, 43, 45)		-- reject plots with certain conditions
							THEN 1
							ELSE 0
						END AS reject_this_plot		-- 1 means this plot should be excluded
					FROM plot_observations po
					JOIN east_us_cond euc
					ON po.current_cn = euc.plt_cn
				)
				-- group back into plot observations, aggregating rejection flags into one flag
				SELECT 
					original_cn,
					current_cn,
					invyr,
					measyear,
					ARRAY_AGG(reject_this_plot) AS rejection_flags,
					MAX(reject_this_plot) AS reject_this_plot
				FROM flagged_conditions
				GROUP BY 
					original_cn,
					current_cn,
					invyr,
					measyear
			)
			-- group back into unique plots, making aliases and years into arrays
			-- turn rejection flags from all the observations into one reject_this_plot flag for the whole plot
			SELECT 
				original_cn,
				ARRAY_AGG(current_cn ORDER BY invyr) AS cn_sequence,
				ARRAY_AGG(invyr ORDER BY invyr) AS invyr_sequence,
				ARRAY_AGG(measyear ORDER BY invyr) AS measyear_sequence, 
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
		UNNEST(fp.measyear_sequence) AS measyear
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

)

-- join plot observations with the trees that were observed there
-- this filters out trees that are on rejected plots
-- each row in this cte is a *tree observation* with original_plot_cn referring to the first time that that plot was observed
SELECT 
	fpo.invyr,
	fpo.measyear,
	mot.original_tree_cn,
	mot.current_tree_cn,
	mot.dia,
	mot.association,
	fpo.original_plot_cn,
	fpo.current_plot_cn
FROM filtered_plot_observations fpo
JOIN multi_obs_trees mot
ON fpo.current_plot_cn = mot.plt_cn

-- TO DO: 
-- add harvested (it will have to come from the cond table in the first outer cte)


