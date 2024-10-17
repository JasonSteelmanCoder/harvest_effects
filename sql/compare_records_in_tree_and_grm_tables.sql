WITH filtered_observations AS (
	WITH every_observation AS (
		WITH multi_obs_trees_not_in_grm AS (
			WITH RECURSIVE tree_cte AS (
				
				SELECT 
					cn AS original_cn,
					array[cn]::bigint[] AS cn_sequence,
					array[statuscd]::double precision[] AS status_sequence,
					array[reconcilecd]::double precision[] AS reconcile_sequence
				FROM east_us_tree
				WHERE prev_tre_cn IS NULL
				
				UNION ALL
			
				SELECT 
					tree_cte.original_cn,
					tree_cte.cn_sequence || east_us_tree.cn,
					tree_cte.status_sequence || east_us_tree.statuscd,
					tree_cte.reconcile_sequence || east_us_tree.reconcilecd
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
				tree_cte.cn_sequence,
				tree_cte.status_sequence,
				tree_cte.reconcile_sequence
			FROM tree_cte
			JOIN obs_nums
			ON 
				tree_cte.original_cn = obs_nums.original_cn
				AND ARRAY_LENGTH(tree_cte.cn_sequence, 1) = obs_nums.num
				WHERE num > 1
			ORDER BY num DESC
		)
		-- unnest the lists for filtering
		SELECT 
			original_cn,
			UNNEST(cn_sequence) AS current_cn,
			UNNEST(status_sequence) AS statuscd,
			UNNEST(reconcile_sequence) AS reconcilecd
		FROM multi_obs_trees_not_in_grm motng
	)
	-- filter the observations according to KaDonna's suggestions
	SELECT 
		*
	FROM every_observation eo
	WHERE 
		reconcilecd != 5
		AND reconcilecd != 6
		AND reconcilecd != 7
		AND reconcilecd != 8 
		AND statuscd != 0
)
-- group the observations by individual tree again
SELECT 
	original_cn,
	ARRAY_AGG(current_cn) AS cn_sequence,
	ARRAY_AGG(statuscd) AS status_sequence,
	ARRAY_AGG(reconcilecd) AS reconcile_sequence
FROM filtered_observations fo
GROUP BY original_cn