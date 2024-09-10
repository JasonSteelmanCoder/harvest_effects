-- Do all states have trees with harvest codes at obs1?

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
-- grab the statecd of trees that have harvested codes on obs1. If 26 state codes return, then all states have test cases.
SELECT
	statecd,
	COUNT(statecd)
FROM tree_year_treatment_of_2x_observed
WHERE (statecd, unitcd, countycd, plot, subp, tree, invyr) 
IN (
	SELECT * FROM obs_1_of_trees		-- only grab the first observation of each tree
)
AND CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN true ELSE false END -- only grab trees harvested on obs1
GROUP BY statecd
