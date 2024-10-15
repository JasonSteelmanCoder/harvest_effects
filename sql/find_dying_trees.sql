WITH indiv_tree_sequences AS (
	WITH tree_statuses AS (
		WITH all_observations AS (
			WITH indiv_trees AS (
				WITH RECURSIVE tree_cte AS (
					
					SELECT 
						cn AS original_cn,
						array[cn]::bigint[] AS cn_sequence
					FROM east_us_tree
					WHERE prev_tre_cn IS NULL
					
					UNION ALL
				
					SELECT 
						tree_cte.original_cn,
						tree_cte.cn_sequence || east_us_tree.cn
					FROM tree_cte
					JOIN east_us_tree
					ON east_us_tree.prev_tre_cn = tree_cte.cn_sequence[ARRAY_LENGTH(tree_cte.cn_sequence, 1)]
						
				), obs_nums AS (
					SELECT 
						original_cn, 
						MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
					FROM tree_cte
					GROUP BY original_cn
				)
				SELECT 
					tree_cte.original_cn, 
					tree_cte.cn_sequence
				FROM tree_cte
				JOIN obs_nums
				ON 
					tree_cte.original_cn = obs_nums.original_cn
					AND ARRAY_LENGTH(tree_cte.cn_sequence, 1) = obs_nums.num
					WHERE num > 1
				ORDER BY num DESC
			)
			-- unnest all of the observations
			SELECT 
				original_cn,
				UNNEST(cn_sequence) AS current_cn
			FROM indiv_trees it
		)
		-- grab the status of the tree at each observation
		SELECT
				ao.*,
				eut.invyr,
				eut.statuscd,
				eut.plt_cn
		FROM all_observations ao
		JOIN east_us_tree eut 
		ON eut.cn = ao.current_cn
	)
	-- group by individual tree again, nesting the observations and their statuses into arrays
	SELECT
		original_cn,
		ARRAY_AGG(current_cn ORDER BY invyr) AS cn_sequence,
		ARRAY_AGG(invyr ORDER BY invyr) AS years,
		ARRAY_AGG(statuscd ORDER BY invyr) AS status,
		ARRAY_AGG(plt_cn ORDER BY invyr) AS plot_sequence
	FROM tree_statuses ts
	GROUP BY original_cn
)
-- only keep individual trees that were live on first observation and dead on the last (cut trees are not included)
SELECT
	its.*
FROM indiv_tree_sequences its
WHERE its.status[1] = 1 								-- live at first observation
	AND its.status[ARRAY_LENGTH(its.status, 1)] = 2		-- dead at last observation
	--AND 657094053126144 = ANY(plot_sequence)
ORDER BY ARRAY_LENGTH(its.status, 1) DESC



