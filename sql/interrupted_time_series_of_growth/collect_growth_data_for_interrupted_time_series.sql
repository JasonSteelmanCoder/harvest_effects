WITH individual_trees_with_spcd AS (
	WITH individual_trees AS (
		WITH prepped_observations AS (
			WITH conditioned_trees AS (
				WITH conditions AS (
					WITH dated_trees AS (
						WITH measured_trees AS (
							WITH multi_obs_trees AS (
								-- find each observation of every multi-observed tree
								SELECT 
									eumot.original_cn,
									UNNEST(eumot.cn_sequence) AS current_cn
								FROM east_us_multi_observed_trees_from_tree_table eumot			-- earlier versions used multi observed trees from the grm table
								WHERE ARRAY_LENGTH(eumot.cn_sequence, 1) > 2		-- accept only trees that were observed at least 3x
							)
							-- add diameter, year, and plot from the tree table
							-- only keep live trees, with valid diameters
							SELECT 
								mot.*,
								eut.dia,
								eut.plt_cn, 
								eut.spcd
							FROM multi_obs_trees mot
							JOIN east_us_tree eut
							ON eut.cn = mot.current_cn
							WHERE eut.dia IS NOT NULL		-- tree must have a valid diameter
								AND eut.statuscd = 1		-- tree must be alive
						)
						-- add measurement year from the plot table
						SELECT 
							mt.*,
							eup.measyear
						FROM measured_trees mt
						JOIN east_us_plot eup 
						ON eup.cn = mt.plt_cn
					)
					-- add harvest codes from the cond table
					-- REMEMBER: one plot can have more than one condition! Each row in this cte is a *condition* on the plot where the tree is.
					SELECT
						dt.*,
						CASE WHEN trtcd1 IS NULL THEN NULL WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN 10 ELSE 0 END AS harvested,
						stdorgcd			-- indicates whether the condition is artificially regenerated
					FROM dated_trees dt
					JOIN east_us_cond euc
					ON euc.plt_cn = dt.plt_cn
				)
				-- group back into individual tree observations, making the harvest codes for each condition into an array
				SELECT 
					cnd.original_cn, 
					cnd.current_cn, 
					cnd.dia, 
					cnd.measyear, 
					cnd.plt_cn,
					cnd.spcd,
					ARRAY_AGG(harvested ORDER BY measyear) AS harvest_conditions,
					ARRAY_AGG(stdorgcd ORDER BY measyear) AS stdorgcd_conditions
				FROM conditions cnd
				GROUP BY original_cn, current_cn, dia, measyear, plt_cn, spcd
				ORDER BY original_cn, measyear, plt_cn
			)
			-- consolidate harvest conditions into one indicator per tree observation
			-- if harvest conditions has a 10, keep a 10 (we know there's harvesting there). if it doesn't have a 10, but does have a null, keep null (there could be harvesting that we don't know about). if it's all zeros, keep 0.
			-- note that each row in this cte is still an *observation* of a tree
			SELECT 
				original_cn, 
				current_cn,
				dia,
				measyear,
				plt_cn,
				spcd,
				harvest_conditions,
				CASE WHEN 10 = ANY(harvest_conditions) THEN 10 WHEN ARRAY_POSITION(harvest_conditions, NULL) IS NOT NULL THEN NULL ELSE 0 END AS harvested,
				stdorgcd_conditions,
				CASE WHEN 1 = ANY(stdorgcd_conditions) THEN 1 WHEN array_remove(stdorgcd_conditions, NULL) IS NULL THEN 2 ELSE 0 END AS remove_as_timberland
			FROM conditioned_trees ct
		)
		-- group all observations back into individual trees
		SELECT 
			po.original_cn,
			ARRAY_AGG(po.current_cn ORDER BY measyear) AS cn_sequence,
			ARRAY_AGG(po.plt_cn ORDER BY measyear) AS plt_cn,
			spcd,
			ARRAY_AGG(po.dia ORDER BY measyear) AS dia,
			ARRAY_AGG(po.measyear ORDER BY measyear) AS measyear,
			ARRAY_AGG(po.harvested ORDER BY measyear) AS harvested,
			ARRAY_AGG(po.remove_as_timberland ORDER BY measyear) AS remove_as_timberland
		FROM prepped_observations po
		GROUP BY original_cn, spcd
	)
	-- only keep trees that were unharvested on their first observation and harvested before the final observation
	-- only keep trees that are on plots that never showed signs of artificial regeneration
	SELECT 
		it.*
	FROM individual_trees it
	WHERE 
		ARRAY_TO_STRING(it.harvested, ',', 'null') ~ '^(0,)+10(\S)+$'		-- the harvest sequence has any number of zeros, followed by a ten, then other values. In other words, it's not harvested in the first observation (or the first few), but it's harvested before the last observation.
		AND 1 != ALL(it.remove_as_timberland) 							-- exclude trees on plots that are artificially regenerated
		AND 2 != ALL(it.remove_as_timberland)							-- exclued trees on plots where stdorgcd is always null
	ORDER BY ARRAY_LENGTH(cn_sequence, 1) DESC
)
-- convert spcd to association
SELECT 
	itws.original_cn, 
	itws.cn_sequence,
	itws.plt_cn, 
	rs.association,
	itws.dia,
	itws.measyear,
	itws.harvested
FROM individual_trees_with_spcd itws
JOIN ref_species rs
ON rs.spcd = itws.spcd


-- output:
-- original_cn
-- cn_sequence (list)
-- plt_cn (list)
-- association
-- dia
-- measyear (list)
-- harvested (list)










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
									array[invyr]::bigint[] AS year_sequence
								FROM east_us_plot
								WHERE prev_plt_cn IS NULL
								
								UNION ALL
							
								SELECT 
									plot_cte.original_cn,
									plot_cte.cn_sequence || east_us_plot.cn,
									plot_cte.year_sequence || east_us_plot.invyr
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
								plot_cte.year_sequence
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
							UNNEST(year_sequence) AS yr
						FROM multi_obs_plots mop
					)
					-- join plot observations with conditions
					-- Remember: there can be more than one condition per plot!
					-- each line of this cte is a *condition*. there is more than one row for each plot observation.
					SELECT 
						original_cn,
						current_cn, 
						yr,
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
					yr,
					ARRAY_AGG(reject_this_plot) AS rejection_flags,
					MAX(reject_this_plot) AS reject_this_plot
				FROM flagged_conditions
				GROUP BY 
					original_cn,
					current_cn,
					yr
			)
			-- group back into unique plots, making aliases and years into arrays
			-- turn rejection flags from all the observations into one reject_this_plot flag for the whole plot
			SELECT 
				original_cn,
				ARRAY_AGG(current_cn ORDER BY yr) AS cn_sequence,
				ARRAY_AGG(yr ORDER BY yr) AS year_sequence,
				ARRAY_AGG(reject_this_plot ORDER BY yr) AS rejection_flags,
				MAX(reject_this_plot) AS reject_this_plot
			FROM flagged_plot_observations
			GROUP BY original_cn
		)
		-- filter out plots that are flagged
		SELECT
			original_cn,
			cn_sequence,
			year_sequence,
			reject_this_plot
		FROM flagged_plots
		WHERE 
			reject_this_plot = 0
	)
	-- unnest again to get plot observations (this time only from filtered plots)
	SELECT 
		fp.original_cn AS original_plot_cn,
		UNNEST(fp.cn_sequence) AS current_plot_cn,
		UNNEST(fp.year_sequence) AS yr
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
	fpo.yr,
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
-- add measyear (it comes from the plot table)
-- add harvested (it will have to come from the cond table in the first outer cte)


