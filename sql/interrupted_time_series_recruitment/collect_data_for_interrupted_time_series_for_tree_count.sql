WITH plot_observation_associations AS (
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
								array[measyear]::bigint[] AS year_sequence
							FROM east_us_plot
							WHERE prev_plt_cn IS NULL
							
							UNION ALL
						
							SELECT 
								plot_cte.original_cn,
								plot_cte.cn_sequence || east_us_plot.cn,
								plot_cte.year_sequence || east_us_plot.measyear
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
						-- unnest the lists into plot-years (also, filter out plots that were not observed enough times)
						SELECT 
							plot_cte.original_cn, 
							UNNEST(plot_cte.cn_sequence) AS cn,
							UNNEST(plot_cte.year_sequence) AS yr
						FROM plot_cte
						JOIN obs_nums
						ON 
							plot_cte.original_cn = obs_nums.original_cn
							AND ARRAY_LENGTH(plot_cte.cn_sequence, 1) = obs_nums.num		-- filter out incomplete arrays left over from construction
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
				AND harvested_sequence[ARRAY_LENGTH(harvested_sequence, 1)] = 0 			-- the final observation must not be harvested or null
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
)
-- group by plot again and put all other variables back into lists
SELECT
	original_cn,
	ARRAY_AGG(cn ORDER BY yr) AS cn_sequence,
	ARRAY_AGG(yr ORDER BY yr) AS year_sequence,
	ARRAY_AGG(harvested ORDER BY yr) AS harvested_sequence,
	ARRAY_AGG(am_trees ORDER BY yr) AS am_trees_sequence,
	ARRAY_AGG(em_trees ORDER BY yr) AS em_trees_sequence,
	ARRAY_AGG(other_trees ORDER BY yr) AS other_trees_sequence
FROM plot_observation_associations poa
GROUP BY original_cn






