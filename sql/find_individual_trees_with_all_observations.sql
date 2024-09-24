WITH RECURSIVE tree_cte AS (
	
	SELECT 
		tre_cn AS root_cn,
		array[tre_cn]::varchar[] AS cn_sequence
	FROM tree_grm_component
	WHERE prev_tre_cn IS NULL
	
	UNION ALL

	SELECT 
		tree_cte.root_cn,
		tree_cte.cn_sequence || tree_grm_component.tre_cn
	FROM tree_cte
	JOIN tree_grm_component
	ON tree_grm_component.prev_tre_cn = tree_cte.cn_sequence[ARRAY_LENGTH(tree_cte.cn_sequence, 1)]
		
), obs_nums AS (
	SELECT 
		root_cn, 
		MAX(ARRAY_LENGTH(cn_sequence, 1))  AS num
	FROM tree_cte
	GROUP BY root_cn
)
SELECT 
	tree_cte.root_cn, 
	tree_cte.cn_sequence
FROM tree_cte
JOIN obs_nums
ON 
	tree_cte.root_cn = obs_nums.root_cn
	AND ARRAY_LENGTH(tree_cte.cn_sequence, 1) = obs_nums.num
	WHERE ARRAY_LENGTH(tree_cte.cn_sequence, 1) > 1
ORDER BY ARRAY_LENGTH(tree_cte.cn_sequence, 1) DESC




