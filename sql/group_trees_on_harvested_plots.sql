-- group into plot observations, aggregating trees into counts
SELECT 
	SUM(CASE WHEN statuscd != 3 AND statuscd IS NOT NULL THEN 1 ELSE 0 END) AS total_trees, 
	SUM(CASE WHEN association = 'AM' AND statuscd != 3 AND statuscd IS NOT NULL THEN 1 ELSE 0 END) AS am_trees,
	SUM(CASE WHEN association = 'EM' AND statuscd != 3 AND statuscd IS NOT NULL THEN 1 ELSE 0 END) AS em_trees,
	SUM(CASE WHEN death_year = obs_year THEN 1 ELSE 0 END) AS total_dying_trees,
	SUM(CASE WHEN death_year = obs_year AND association = 'AM' THEN 1 ELSE 0 END) AS dying_am_trees,
	SUM(CASE WHEN death_year = obs_year AND association = 'EM' THEN 1 ELSE 0 END) AS dying_em_trees,
	current_plot_cn, 
	original_plot_cn,
	first_harvest_year,
	obs_year,
	obs_number
FROM a_temp
GROUP BY 
	current_plot_cn, 
	original_plot_cn,
	first_harvest_year,
	obs_year,
	obs_number

