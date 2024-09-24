WITH RECURSIVE tree_cte AS (
	
	SELECT 
		tre_cn AS original_cn,
		array[tre_cn]::bigint[] AS cn_sequence
	FROM east_us_tree_grm_component
	WHERE prev_tre_cn IS NULL
	
	UNION ALL

	SELECT 
		tree_cte.original_cn,
		tree_cte.cn_sequence || east_us_tree_grm_component.tre_cn
	FROM tree_cte
	JOIN east_us_tree_grm_component
	ON east_us_tree_grm_component.prev_tre_cn = tree_cte.cn_sequence[ARRAY_LENGTH(tree_cte.cn_sequence, 1)]
		
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




