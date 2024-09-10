-- For how many trees does the first observation show evidence of harvesting? 

WITH obs_1_of_trees AS (
	-- grab all of the first observations of trees
	SELECT 
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree, 
		MIN(invyr) AS invyr
	FROM tree_year_treatment_of_2x_observed
	GROUP BY 
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree
	ORDER BY
		statecd, 
		unitcd, 
		countycd, 
		plot, 
		subp, 
		tree, 
		invyr
)
-- Find the number of trees whose plots are harvested at obs1 and the number whose plots are not
SELECT
	CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN true ELSE false END AS harvested_on_obs1, 
	COUNT(CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN true ELSE false END) AS num_trees
FROM tree_year_treatment_of_2x_observed
WHERE (statecd, unitcd, countycd, plot, subp, tree, invyr)
IN (
	SELECT * FROM obs_1_of_trees
)
GROUP BY CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN true ELSE false END

