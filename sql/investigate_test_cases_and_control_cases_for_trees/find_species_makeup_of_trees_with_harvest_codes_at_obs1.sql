-- What is the species makeup of trees with harvest codes at obs1?

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
	FROM tree_year_treatment
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
-- grab the species code for each tree with harvest codes at obs1
SELECT
	spcd, 
	COUNT(spcd) AS trees_with_harvest_codes
FROM tree_year_treatment tyt
JOIN east_us_tree eut 
ON tyt.statecd = eut.statecd 
	AND tyt.unitcd = eut.unitcd
	AND tyt.countycd = eut.countycd
	AND tyt.plot = eut.plot
	AND tyt.subp = eut.subp
	AND tyt.tree = eut.tree
	AND tyt.invyr = eut.invyr
WHERE (tyt.statecd, tyt.unitcd, tyt.countycd, tyt.plot, tyt.subp, tyt.tree, tyt.invyr) 
IN (
	SELECT * FROM obs_1_of_trees		-- only grab the first observation of each tree
)
AND CASE WHEN (tyt.trtcd1 = 10 OR tyt.trtcd2 = 10 OR tyt.trtcd3 = 10) THEN true ELSE false END -- only grab trees harvested on obs1
GROUP BY spcd
ORDER BY trees_with_harvest_codes DESC
