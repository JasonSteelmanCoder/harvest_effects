WITH filtered_plot_observations AS (
	WITH harvest_sequences AS (
		WITH harvested_plots AS (
			WITH harvested_plot_years AS (
				WITH multi_obs_plot_years AS (
					WITH RECURSIVE plot_cte AS (
					
						-- grab each plot with a list of its aliases and years
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
						-- grab the number of observations for each plot
						SELECT 
							original_cn, 
							MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
						FROM plot_cte
						GROUP BY original_cn
					)
					-- unnest the lists into plot-years (also, drop plots that were only observed once)
					SELECT 
						plot_cte.original_cn, 
						UNNEST(plot_cte.cn_sequence) AS cn,
						UNNEST(plot_cte.year_sequence) AS yr
					FROM plot_cte
					JOIN obs_nums
					ON 
						plot_cte.original_cn = obs_nums.original_cn
						AND ARRAY_LENGTH(plot_cte.cn_sequence, 1) = obs_nums.num
					WHERE num > 3			-- only accept plots that were observed at least four times
					ORDER BY num DESC
				)
				-- check for harvesting in each plot-year
				SELECT 
					mopy.*,
					MAX(CASE 
						WHEN euc.trtcd1 = 10 OR euc.trtcd2 = 10 OR euc.trtcd3 = 10
						THEN 10
						WHEN euc.trtcd1 IS NULL AND euc.trtcd2 IS NULL AND euc.trtcd3 IS NULL
						THEN NULL
						ELSE 0
					END) AS harvested
				FROM multi_obs_plot_years mopy
				JOIN east_us_cond euc 		-- check on loss of ~100 rows here (probably some plots don't have any conditions?)
				ON euc.plt_cn = mopy.cn
				GROUP BY mopy.original_cn, mopy.cn, mopy.yr
			)
			-- group by plot again, turning cn yr and harvested into lists (this lets us filter out extraneous plots before searching the tree table)
			SELECT 
				original_cn,
				ARRAY_AGG(cn ORDER BY yr) AS cn_sequence,
				ARRAY_AGG(yr ORDER BY yr) AS year_sequence,
				ARRAY_AGG(harvested ORDER BY yr) AS harvested_sequence
			FROM harvested_plot_years hpy
			GROUP BY original_cn
		)
		-- filter out plots whose harvest sequences don't work for interrupted time series analysis
		SELECT 
			*
		FROM harvested_plots
		WHERE harvested_sequence[1] = 0					-- the plot must not be harvested on the first observation
			AND harvested_sequence[2] = 0					-- the plot must not be harvested on the second observation
			AND 10 = ANY(harvested_sequence[3:ARRAY_LENGTH(harvested_sequence, 1) - 1])		-- the plot must be harvested between the second and last observations
		ORDER BY ARRAY_LENGTH(cn_sequence, 1) DESC
	)
	-- unnest the lists again so that we'll be able to get the tree counts for each relevant plot observation
	SELECT  
		hs.original_cn,
		UNNEST(hs.cn_sequence) AS cn,
		UNNEST(hs.year_sequence) AS yr,
		UNNEST(hs.harvested_sequence) AS harvested
	FROM harvest_sequences hs
)
-- find the tree counts for each relevant plot observation
SELECT 
	fpo.*,
	SUM(CASE WHEN rs.association = 'AM' THEN 1 ELSE 0 END) AS am_trees,
	SUM(CASE WHEN rs.association = 'EM' THEN 1 ELSE 0 END) AS em_trees,
	SUM(CASE WHEN rs.association != 'AM' AND rs.association != 'EM' THEN 1 ELSE 0 END) AS other_trees
FROM filtered_plot_observations fpo
LEFT JOIN east_us_tree eut
ON eut.plt_cn = fpo.cn
LEFT JOIN ref_species rs
ON rs.spcd = eut.spcd
GROUP BY fpo.original_cn, fpo.cn, fpo.yr, fpo.harvested













-- ##
-- DEPRECATED
-- ##
WITH multi_obs_plots AS (
	WITH plot_years_full AS (
		WITH row_per_tree_associated AS (
			WITH row_per_tree AS (
				WITH plot_years AS (
					-- grab plot-years 
						-- aggregate trtcds from all of the conditions (remember that there may be more than one condition per plot)
						-- aggregate agg_trtcds1-3 into one yearly_trtcd
					SELECT 
						euc.statecd,
						euc.unitcd,
						euc.countycd,
						euc.plot,
						euc.invyr,
						MAX(CASE WHEN euc.trtcd1 = 10 THEN 10 ELSE 0 END) AS agg_trtcd1,
						MAX(CASE WHEN euc.trtcd2 = 10 THEN 10 ELSE 0 END) AS agg_trtcd2,
						MAX(CASE WHEN euc.trtcd3 = 10 THEN 10 ELSE 0 END) AS agg_trtcd3,
						CASE 
							WHEN (
								MAX(CASE WHEN euc.trtcd1 = 10 THEN 10 ELSE 0 END) = 10
								OR MAX(CASE WHEN euc.trtcd2 = 10 THEN 10 ELSE 0 END) = 10
								OR MAX(CASE WHEN euc.trtcd3 = 10 THEN 10 ELSE 0 END) = 10
							) 
							THEN 10 
							ELSE 0 
						END AS yearly_trtcd
					FROM east_us_cond euc
					WHERE 
						euc.trtcd1 IS NOT NULL
						AND euc.trtcd2 IS NOT NULL
						AND euc.trtcd3 IS NOT NULL
					GROUP BY
						euc.statecd,
						euc.unitcd,
						euc.countycd,
						euc.plot,
						euc.invyr
					ORDER BY 
						euc.statecd,
						euc.unitcd,
						euc.countycd,
						euc.plot,
						euc.invyr
				)
				-- make a row for each tree (include association)
				SELECT 
					py.statecd,
					py.unitcd,
					py.countycd,
					py.plot,
					py.invyr,
					py.agg_trtcd1,
					py.agg_trtcd2,
					py.agg_trtcd3,
					py.yearly_trtcd,
					eut.spcd,
					eut.statuscd
				FROM plot_years py
				LEFT JOIN east_us_tree eut		-- left join allows plot-years with zero trees
				ON 
					eut.statecd = py.statecd
					AND eut.unitcd = py.unitcd
					AND eut.countycd = py.countycd
					AND eut.plot = py.plot
					AND eut.invyr = py.invyr
			)
			-- make spcd into association
			SELECT 
				statecd,
				unitcd,
				countycd,
				plot,
				invyr,
				yearly_trtcd,
				rs.association,
				statuscd
			FROM row_per_tree rpt
			LEFT JOIN ref_species rs 
			ON rs.spcd = rpt.spcd
		)
		-- group by plot-year while counting AM and EM trees (exclude dead trees from count)
		SELECT
			statecd, 
			unitcd,
			countycd,
			plot, 
			invyr,
			MAX(yearly_trtcd) AS yearly_trtcd,			-- there is only one yearly_trtcd per plot-year, so keep it the same.
			SUM(CASE WHEN (association = 'AM' AND statuscd = 1) THEN 1 ELSE 0 END) AS am_trees,
			SUM(CASE WHEN (association = 'EM' AND statuscd = 1) THEN 1 ELSE 0 END) AS em_trees,
			SUM(CASE WHEN (association != 'AM' AND association != 'EM' AND statuscd = 1) THEN 1 ELSE 0 END) AS other_trees
		FROM row_per_tree_associated rpta
		GROUP BY 
			statecd, 
			unitcd,
			countycd,
			plot, 
			invyr
	)
	-- group by plot, making years, trtcds, and tree counts into arrays
	SELECT 
		statecd,
		unitcd, 
		countycd,
		plot,
		ARRAY_AGG(invyr ORDER BY invyr) AS obs_years,
		ARRAY_AGG(yearly_trtcd ORDER BY invyr) AS yearly_trtcd,
		ARRAY_AGG(am_trees ORDER BY invyr) AS am_trees,
		ARRAY_AGG(em_trees ORDER BY invyr) AS em_trees,
		ARRAY_AGG(other_trees ORDER BY invyr) AS other_trees 
	FROM plot_years_full pyf
	GROUP BY 
		statecd,
		unitcd, 
		countycd,
		plot
	HAVING 
		ARRAY_LENGTH(ARRAY_AGG(invyr ORDER BY invyr), 1) > 3		-- only accept plots with at least four observations
)
-- limit the output to plots that are valid for interrupted time series analysis: they can't be harvested on the first or second, but must be observed on a middle observation (not first, second, or last obs)
SELECT 
	*
FROM multi_obs_plots mop
WHERE 
	yearly_trtcd[1] = 0													-- plot must not be harvested on the first observation
	AND yearly_trtcd[2] = 0												-- plot must not be harvested on second observation
	AND 10 = ANY(yearly_trtcd[2:ARRAY_LENGTH(yearly_trtcd, 1) - 1])		-- plot must be harvested between the second and last observations







