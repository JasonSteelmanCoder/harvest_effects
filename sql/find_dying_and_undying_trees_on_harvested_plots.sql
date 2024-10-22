WITH filtered_plot_observations AS (
	WITH unfiltered_observations AS (
		WITH harvested_observations AS (
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
				WHERE num > 2		-- the plot needs to have been observed at least three times
				ORDER BY num DESC
			)
			-- check for harvesting each plot year
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY original_cn
					ORDER BY yr
				) AS obs_number,
				pobs.*,
				MAX(CASE 
					WHEN euc.trtcd1 = 10 OR euc.trtcd2 = 10 OR euc.trtcd3 = 10
					THEN 10
					WHEN euc.trtcd1 IS NULL AND euc.trtcd2 IS NULL AND euc.trtcd3 IS NULL
					THEN NULL
					ELSE 0
				END) AS harvested,
				(MAX(MAX(CASE 
					WHEN euc.trtcd1 = 10 OR euc.trtcd2 = 10 OR euc.trtcd3 = 10
					THEN 10
					WHEN euc.trtcd1 IS NULL AND euc.trtcd2 IS NULL AND euc.trtcd3 IS NULL
					THEN NULL
					ELSE 0
				END)) OVER (
					PARTITION BY original_cn
					ORDER BY yr
				)::DECIMAL / 10)::SMALLINT AS previously_harvested   -- retuns 1 for "has been harvested and zero for never harvested"	
			FROM plot_observations pobs
			JOIN east_us_cond euc 		-- check on loss of ~100 rows here (probably some plots don't have any conditions?)
			ON euc.plt_cn = pobs.current_cn
			GROUP BY pobs.original_cn, pobs.current_cn, pobs.yr	
			ORDER BY original_cn DESC, yr
		)
		-- add columns indicating whether a plot was harvested on first observation and whether its harvest was before the last observation
		SELECT
			obs_number,
			original_cn,
			current_cn,
			yr,
			harvested,
			previously_harvested,
			SUM(previously_harvested) FILTER (WHERE previously_harvested IS NOT NULL) OVER (
				PARTITION BY original_cn
			) AS num_post_harvest_obs, 		-- puts the total number of post-harvest observations for the plot in every row
			FIRST_VALUE(previously_harvested) OVER (
				PARTITION BY original_cn
				ORDER BY yr
			) AS first_observation_harvested
		FROM harvested_observations hobs
		ORDER BY 
			original_cn DESC, 
			obs_number
	)
	-- only keep observations for plots that are unharvested on their first observation
	-- and have at least one additional observation after their first harvest
	-- add a column for first harvest year
	SELECT 
		obs_number,
		original_cn,
		current_cn,
		yr,
		harvested,
		previously_harvested,
		MIN(yr) FILTER(WHERE previously_harvested = 1) OVER (
			PARTITION BY original_cn
		) AS first_harvest_year
	FROM unfiltered_observations unfobs
	WHERE 
		first_observation_harvested = 0 	-- the plot must be unharvested at the first observation
		AND num_post_harvest_obs > 1		-- the plot must have at least one additional observation after the first harvest
	ORDER BY 
		original_cn DESC, 
		obs_number
), 



original_plots AS (

	SELECT 
		original_cn AS original_plot_cn,
		UNNEST(cn_sequence) AS current_plot_cn
	FROM east_us_multi_observed_plots
	
),



trees AS (
	WITH relevant_trees AS (
		WITH RECURSIVE tree_cte AS (
		
		SELECT 
			cn AS original_cn,
			array[cn]::bigint[] AS cn_sequence,
			array[invyr]::smallint[] AS year_sequence,
			array[statuscd]::smallint[] AS status_sequence,
			array[plt_cn]::bigint[] AS plt_cn_sequence,
			spcd
		FROM east_us_tree
		WHERE prev_tre_cn IS NULL
		
		UNION ALL
	
		SELECT 
			tree_cte.original_cn,
			tree_cte.cn_sequence || east_us_tree.cn,
			tree_cte.year_sequence || east_us_tree.invyr,
			tree_cte.status_sequence || east_us_tree.statuscd,
			tree_cte.plt_cn_sequence || east_us_tree.plt_cn,
			tree_cte.spcd
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
	-- grab each tree observation with its sequence of aliases
	SELECT 
		tree_cte.original_cn AS original_tree_cn, 
		UNNEST(tree_cte.cn_sequence) AS current_tree_cn,
		UNNEST(tree_cte.year_sequence) AS tree_yr,
		UNNEST(tree_cte.status_sequence) AS statuscd,
		UNNEST(tree_cte.plt_cn_sequence) AS tree_plot_cn,
		spcd
	FROM tree_cte
	JOIN obs_nums
	ON 
		tree_cte.original_cn = obs_nums.original_cn
		AND ARRAY_LENGTH(tree_cte.cn_sequence, 1) = obs_nums.num
		WHERE num > 1			-- the tree must be observed more than once
			AND tree_cte.status_sequence[1] = 1 		-- the tree must be alive at first
			AND tree_cte.status_sequence[ARRAY_LENGTH(tree_cte.status_sequence, 1)] = 2 -- the tree must die naturally
	ORDER BY original_tree_cn, tree_yr
)
-- add a column for death year
SELECT 
	original_tree_cn,
	current_tree_cn,
	tree_yr,
	statuscd,
	MIN(tree_yr) FILTER(WHERE statuscd = 2) OVER (
		PARTITION BY original_tree_cn
	) AS death_year,
	spcd,
	tree_plot_cn
FROM relevant_trees

),



prepared_trees AS (

	SELECT 
		original_tree_cn,
		current_tree_cn,
		tree_yr,
		statuscd,
		death_year,
		rs.association,
		op.original_plot_cn
	FROM trees
	JOIN original_plots op
	ON op.current_plot_cn = trees.tree_plot_cn
	JOIN ref_species rs
	ON rs.spcd = trees.spcd
	
)
-- grab every relevant tree with its matching plot observation
-- there will one row for each tree
-- there will be multiple rows for each plot observation
SELECT 
	obs_number,
	original_plot_cn,
	current_cn AS current_plot_cn,
	yr,
	-- harvested,
	-- previously_harvested,
	first_harvest_year,
	original_tree_cn,
	statuscd,
	death_year,
	association
FROM filtered_plot_observations fpo
JOIN prepared_trees pt
ON pt.original_plot_cn = fpo.original_cn
	AND pt.tree_yr = fpo.yr






--
-- DEPRECATED
--
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
	WHERE uhp.harvested_sequence[1] = 0                                                 -- the first observation needs to be unharvested
        AND 10 = ANY(uhp.harvested_sequence[1:uhp.harvested_sequence[ARRAY_LENGTH(uhp.harvested_sequence, 1) - 1]]) -- an observation before the last one shows harvesting

	
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










