WITH RECURSIVE plot_cte AS (
	
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
WHERE num > 1
ORDER BY num DESC