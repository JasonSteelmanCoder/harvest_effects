WITH harvested_multi_obs_plots AS (
	WITH unfiltered_harvested_plots AS (
		WITH harvested_plot_observations AS (
			WITH plot_observations AS (
				WITH RECURSIVE plot_cte AS (
					-- grab each individual plot with all of its aliases and years
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
					-- count the number of observations for each plot
					SELECT 
						original_cn, 
						MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
					FROM plot_cte
					GROUP BY original_cn
				)
				-- unnest the cn and year sequences to get individual observations
				-- also, filter out unnecessary rows
				SELECT 
					plot_cte.original_cn, 
					UNNEST(plot_cte.cn_sequence) AS current_cn,
					UNNEST(plot_cte.year_sequence) AS yr
				FROM plot_cte
				JOIN obs_nums
				ON 
					plot_cte.original_cn = obs_nums.original_cn
					AND ARRAY_LENGTH(plot_cte.cn_sequence, 1) = obs_nums.num		-- filter out incomplete arrays left over from construction
				WHERE num > 1		-- the plot needs to have been observed at least twice
				ORDER BY num DESC
			)
			-- check for harvesting each plot year
			SELECT 
				pobs.*,
				MAX(CASE 
					WHEN euc.trtcd1 = 10 OR euc.trtcd2 = 10 OR euc.trtcd3 = 10
					THEN 10
					WHEN euc.trtcd1 IS NULL AND euc.trtcd2 IS NULL AND euc.trtcd3 IS NULL
					THEN NULL
					ELSE 0
				END) AS harvested
			FROM plot_observations pobs
			JOIN east_us_cond euc 		-- check on loss of ~100 rows here (probably some plots don't have any conditions?)
			ON euc.plt_cn = pobs.current_cn
			GROUP BY pobs.original_cn, pobs.current_cn, pobs.yr	
		)
		-- group by plot again, aggregating the other variables into arrays
		SELECT 
			hpo.original_cn,
			ARRAY_AGG(hpo.current_cn ORDER BY hpo.yr) AS cn_sequence,
			ARRAY_AGG(hpo.yr ORDER BY hpo.yr) AS year_sequence,
			ARRAY_AGG(hpo.harvested ORDER BY hpo.yr) AS harvested_sequence
		FROM harvested_plot_observations hpo
		GROUP BY hpo.original_cn
	)
	-- only select plots that have harvesting before their last observation
	SELECT *
	FROM unfiltered_harvested_plots uhp
	WHERE 10 = ANY(uhp.harvested_sequence[1:uhp.harvested_sequence[ARRAY_LENGTH(uhp.harvested_sequence, 1) - 1]]) -- an observation before the last one shows harvesting

	
),


original_plots AS (

	SELECT 
		original_cn,
		UNNEST(cn_sequence) AS current_cn
	FROM east_us_multi_observed_plots

),


individual_trees AS (	

    WITH RECURSIVE tree_cte AS (
        -- grab each individual tree with all of its aliases
        SELECT 
            cn AS original_cn,
            spcd,
            array[cn]::bigint[] AS cn_sequence,
            array[invyr]::smallint[] AS year_sequence,
            array[statuscd]::smallint[] AS status_sequence,
            array[plt_cn]::bigint[] AS plt_cn_sequence
        FROM east_us_tree
        WHERE prev_tre_cn IS NULL
        
        UNION ALL
    
        SELECT 
            tree_cte.original_cn,
            tree_cte.spcd,
            tree_cte.cn_sequence || east_us_tree.cn,
            tree_cte.year_sequence || east_us_tree.invyr,
            tree_cte.status_sequence || east_us_tree.statuscd,
            tree_cte.plt_cn_sequence || east_us_tree.plt_cn
        FROM tree_cte
        JOIN east_us_tree
        ON east_us_tree.prev_tre_cn = tree_cte.cn_sequence[ARRAY_LENGTH(tree_cte.cn_sequence, 1)]
            
    ), obs_nums AS (
        -- count the number of observations for each tree
        SELECT 
            original_cn, 
            MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
        FROM tree_cte
        GROUP BY original_cn
    )
    -- filter out the incomplete arrays of observations
    SELECT 
        tree_cte.original_cn AS original_tree_cn, 
        tree_cte.spcd,
        tree_cte.cn_sequence AS tree_cn_sequence,
        tree_cte.year_sequence AS tree_year_sequence,
        tree_cte.status_sequence AS tree_status_sequence,
        tree_cte.plt_cn_sequence AS tree_plt_cn_sequence
    FROM tree_cte
    JOIN obs_nums
    ON 
        tree_cte.original_cn = obs_nums.original_cn
        AND ARRAY_LENGTH(tree_cte.cn_sequence, 1) = obs_nums.num		-- filter out incomplete arrays left over from construction
        WHERE num > 1 		-- the tree needs to have been observed at least twice
    ORDER BY num DESC

), 

prepared_trees AS (

	-- grab each tree with its plot's original cn
	SELECT 
		it.*,
		op.original_cn AS original_plot_cn
	FROM individual_trees it
	JOIN original_plots op				-- (this join filters out trees on single-observation plots)
	ON it.tree_plt_cn_sequence[1] = op.current_cn

)
-- grab each relevant plot with its relevant trees (there will be multiple rows for each plot, and one row for each tree.)
SELECT
	hmop.original_cn AS plot_original_cn,
	hmop.cn_sequence AS plot_cn_sequence,
	hmop.year_sequence AS plot_year_sequence,
	hmop.harvested_sequence AS plot_harvested_sequence,
	pt.original_tree_cn,
	pt.tree_cn_sequence,
	pt.tree_year_sequence,
	pt.tree_status_sequence,
	pt.tree_plt_cn_sequence,
	rs.association
FROM harvested_multi_obs_plots hmop
JOIN prepared_trees pt
ON hmop.original_cn = pt.original_plot_cn
JOIN ref_species rs 
ON rs.spcd = pt.spcd










