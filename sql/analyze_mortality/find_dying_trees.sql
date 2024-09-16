CREATE TABLE dying_trees AS (
	-- find all of the trees that are alive on the first_obs but dead on the last_obs (not counting trees that were cut)
	
	WITH live_on_first_obs AS (
		-- grab trees that were alive in their first obs year along with their harvested status and alive/dead status
		SELECT
			mot.statecd, 
			mot.unitcd,
			mot.countycd,
			mot.plot,
			mot.subp,
			mot.tree,
			mot.first_obs,
			eut.statuscd,
            eut.condid
		FROM multi_obs_trees_all_statuses mot
		JOIN east_us_tree eut
		ON 
			mot.first_obs = eut.invyr		-- only grab the first observation of each tree
			AND mot.statecd = eut.statecd
			AND mot.unitcd = eut.unitcd
			AND mot.countycd = eut.countycd
			AND mot.plot = eut.plot
			AND mot.subp = eut.subp
			AND mot.tree = eut.tree
		WHERE statuscd = 1				-- only grab trees that are alive
	), live_filtered_multi_obs_trees AS (
		-- for all trees that are live in the first obs, grab their row from the original multi_obs_trees_all_statuses table (plus their condid)
		SELECT 
			mot2.statecd, 
			mot2.unitcd, 
			mot2.countycd, 
			mot2.plot, 
			mot2.subp, 
			mot2.tree, 
			mot2.first_obs, 
			mot2.last_obs, 
			mot2.num_obs,
            lofo.condid
		FROM multi_obs_trees_all_statuses mot2
		JOIN live_on_first_obs lofo
		ON 
			lofo.first_obs = mot2.first_obs
			AND lofo.statecd = mot2.statecd
			AND lofo.unitcd = mot2.unitcd
			AND lofo.countycd = mot2.countycd
			AND lofo.plot = mot2.plot
			AND lofo.subp = mot2.subp
			AND lofo.tree = mot2.tree
	)
	-- grab the trees that were live at first observation, but dead at last observation
	SELECT 
		eut.statecd,
		eut.unitcd,
		eut.countycd,
		eut.plot,
		eut.subp,
		eut.tree,
		eut.spcd,
		lf.first_obs,
		lf.last_obs,
		lf.num_obs,
        lf.condid
	FROM live_filtered_multi_obs_trees lf
	JOIN east_us_tree eut
	ON 
		lf.last_obs = eut.invyr		-- only grab rows where the year is the last_obs year
		AND lf.statecd = eut.statecd
		AND lf.unitcd = eut.unitcd
		AND lf.countycd = eut.countycd
		AND lf.plot = eut.plot
		AND lf.subp = eut.subp
		AND lf.tree = eut.tree
	WHERE eut.statuscd = 2			-- only accept trees that are dead on their last observation (not including cut trees and trees missing statuscd for the last_obs)
)
	
	