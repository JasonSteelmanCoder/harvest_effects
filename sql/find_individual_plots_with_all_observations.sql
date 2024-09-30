WITH RECURSIVE plot_cte AS (
	
	SELECT 
		cn AS original_cn,
		array[cn]::bigint[] AS cn_sequence,
		array[statecd] AS state_sequence,
		array[countycd] AS county_sequence,
		array[plot]::bigint[] AS plot_sequence,
		array[invyr]::bigint[] AS year_sequence
	FROM east_us_plot
	WHERE prev_plt_cn IS NULL
	
	UNION ALL

	SELECT 
		plot_cte.original_cn,
		plot_cte.cn_sequence || east_us_plot.cn,
		plot_cte.state_sequence || east_us_plot.statecd,
		plot_cte.county_sequence || east_us_plot.countycd,
		plot_cte.plot_sequence || east_us_plot.plot,
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
	plot_cte.year_sequence,
	plot_cte.state_sequence,
	plot_cte.county_sequence,
	plot_cte.plot_sequence
	-- plot_cte.year_sequence[1] AS first_year,
	-- plot_cte.year_sequence[ARRAY_LENGTH(plot_cte.year_sequence, 1)] AS last_year
FROM plot_cte
JOIN obs_nums
ON 
	plot_cte.original_cn = obs_nums.original_cn
	AND ARRAY_LENGTH(plot_cte.cn_sequence, 1) = obs_nums.num
WHERE num > 1
	AND plot_cte.plot_sequence[1] != plot_cte.plot_sequence[ARRAY_LENGTH(plot_cte.plot_sequence, 1)]
ORDER BY num DESC