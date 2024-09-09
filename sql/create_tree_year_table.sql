-- find all tree-years with their treatment codes
CREATE TABLE tree_yr AS (
	WITH multi_obs_trees AS (
		SELECT statecd, unitcd, countycd, plot, subp, tree, COUNT(invyr) AS num_obs
		FROM east_us_tree
		WHERE 
			statuscd = 1					-- only accept live trees
			AND invyr != 9999
		GROUP BY statecd, unitcd, countycd, plot, subp, tree 
		HAVING COUNT(invyr) > 1
		ORDER BY COUNT(invyr)
	)
	SELECT 
		east_us_tree.statecd, 
		east_us_tree.unitcd, 
		east_us_tree.countycd, 
		east_us_tree.plot,
		east_us_tree.subp,
		east_us_tree.tree, 
		east_us_tree.invyr, 
		east_us_cond.trtcd1,
		east_us_cond.trtcd2,
		east_us_cond.trtcd3,
		multi_obs_trees.num_obs
	FROM east_us_tree
	JOIN east_us_cond
	ON 
		east_us_tree.statecd = east_us_cond.statecd
		AND east_us_tree.unitcd = east_us_cond.unitcd
		AND east_us_tree.countycd = east_us_cond.countycd
		AND east_us_tree.plot::text = east_us_cond.plot
		AND east_us_tree.invyr = east_us_cond.invyr
		AND east_us_tree.condid = east_us_cond.condid
	LEFT JOIN multi_obs_trees
	ON 
		east_us_tree.statecd = multi_obs_trees.statecd
		AND east_us_tree.unitcd = multi_obs_trees.unitcd
		AND east_us_tree.countycd = multi_obs_trees.countycd
		AND east_us_tree.plot = multi_obs_trees.plot
		AND east_us_tree.subp = multi_obs_trees.subp
		AND east_us_tree.tree = multi_obs_trees.tree
	WHERE 
		east_us_tree.statuscd = 1					-- only accept live trees
		AND east_us_tree.invyr != 9999
	GROUP BY 
		east_us_tree.statecd, 
		east_us_tree.unitcd, 
		east_us_tree.countycd, 
		east_us_tree.plot, 
		east_us_tree.subp,
		east_us_tree.tree, 
		east_us_tree.invyr, 
		east_us_cond.trtcd1, 
		east_us_cond.trtcd2, 
		east_us_cond.trtcd3,
		multi_obs_trees.num_obs
	ORDER BY 
		east_us_tree.statecd, 
		east_us_tree.unitcd, 
		east_us_tree.countycd, 
		east_us_tree.plot, 
		east_us_tree.subp, 
		east_us_tree.tree, 
		east_us_tree.invyr
)