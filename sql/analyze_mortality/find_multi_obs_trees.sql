CREATE TABLE multi_obs_trees_all_statuses AS (
    -- grab all trees that are observed at least twice (including observations of dead trees)
	SELECT 
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree, 
		MIN(invyr) AS first_obs, 
		MAX(invyr) AS last_obs,
		COUNT(invyr) AS num_obs 
	FROM east_us_tree
	WHERE 
		invyr != 9999
	GROUP BY statecd, unitcd, countycd, plot, subp, tree
	HAVING COUNT(invyr) > 1
	ORDER BY 
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree
)

