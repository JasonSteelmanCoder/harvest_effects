-- Find average yearly growth for different harvesting cases
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
-- Find average yearly growth for different harvesting cases
SELECT harvested_on_obs1, 
	-- association,
	AVG(growth_per_year) AS avg_growth_per_year
FROM growth_per_year
-- WHERE association = 'AM' or association = 'EM'
GROUP BY 
	harvested_on_obs1 
	-- , association