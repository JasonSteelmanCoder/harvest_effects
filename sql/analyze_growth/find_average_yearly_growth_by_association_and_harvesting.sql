-- Find average yearly growth for different combinations of harvesting and mycorrhizal associations
WITH growth_per_year AS (
	-- Grab the growth per year for each tree
	SELECT statecd,
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree,
		harvested_on_obs1, 
		scientific_name, 
		association,
		ROUND(dia_last_obs::decimal - dia_obs1::decimal, 4) AS total_growth,
		years_elapsed,
		ROUND((dia_last_obs - dia_obs1)::decimal / years_elapsed::decimal, 4) AS growth_per_year
	FROM growth
	WHERE dia_last_obs IS NOT NULL
)
-- Find average yearly growth for different combinations of harvesting and mycorrhizal associations
SELECT harvested_on_obs1,
	association,
	COUNT(tree) AS trees,
	AVG(growth_per_year) AS avg_growth_per_year
FROM growth_per_year
-- WHERE association IN ('AM', 'EM')
GROUP BY harvested_on_obs1, association
ORDER BY trees DESC, harvested_on_obs1, association






