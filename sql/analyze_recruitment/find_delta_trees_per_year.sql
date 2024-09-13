CREATE TABLE delta_trees_per_year AS (
	SELECT 
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		years_elapsed, 
		harvested_at_obs1, 
		ROUND((num_am_trees_last_obs - num_am_trees_obs1) / years_elapsed::decimal, 5) AS delta_am_trees_per_year,
		ROUND((num_em_trees_last_obs - num_em_trees_obs1) / years_elapsed::decimal, 5) AS delta_em_trees_per_year
	FROM recruitment
)