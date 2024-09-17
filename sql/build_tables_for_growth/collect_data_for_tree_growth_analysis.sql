-- Collect everything we need to assess the effects of harvesting on tree growth 
WITH tree_dates_and_harvested AS (
	WITH obs_1_of_trees AS (
		-- grab all of the first observations of trees
		SELECT 
			statecd, 
			unitcd, 
			countycd, 
			plot, 
			subp, 
			tree, 
			MIN(invyr) AS obs1
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
			obs1
	), 
	last_obs AS (
		-- grab all of the last observations of trees
		SELECT 
			statecd, 
			unitcd, 
			countycd, 
			plot, 
			subp, 
			tree, 
			MAX(invyr) AS last_obs
		FROM tree_year_treatment_of_2x_observed
		WHERE (statecd, unitcd, countycd, plot, subp, tree)
			IN (
				SELECT statecd, unitcd, countycd, plot, subp, tree FROM obs_1_of_trees
			)
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
			last_obs
	)
	-- Grab the each tree, its first observation years, and its harvested status
	SELECT
		tyt.statecd, 
		tyt.unitcd, 
		tyt.countycd, 
		tyt.plot, 
		tyt.subp, 
		tyt.tree, 
		tyt.invyr AS obs1,
		last_obs,
		last_obs - tyt.invyr AS years_elapsed,
		CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN true ELSE false END AS harvested_on_obs1 
	FROM tree_year_treatment_of_2x_observed tyt
	JOIN last_obs lo
	ON tyt.statecd = lo.statecd
		AND tyt.unitcd = lo.unitcd
		AND tyt.countycd = lo.countycd
		AND tyt.plot = lo.plot
		AND tyt.subp = lo.subp
		AND tyt.tree = lo.tree
	WHERE (tyt.statecd, tyt.unitcd, tyt.countycd, tyt.plot, tyt.subp, tyt.tree, tyt.invyr)
	IN (
		SELECT * FROM obs_1_of_trees
	)
	AND trtcd1 IS NOT NULL AND trtcd2 IS NOT NULL AND trtcd3 IS NOT NULL
	ORDER BY 
		tyt.statecd, 
		tyt.unitcd, 
		tyt.countycd, 
		tyt.plot, 
		tyt.subp, 
		tyt.tree, 
		tyt.invyr
)
-- grab everything we need to analyze the effects of harvesting on individual trees' growth rates
SELECT 
	tdh.statecd, 
	tdh.unitcd, 
	tdh.countycd, 
	tdh.plot, 
	tdh.subp, 
	tdh.tree, 
	tdh.obs1, 
	tdh.last_obs, 
	tdh.years_elapsed, 
	tdh.harvested_on_obs1,
	eut1.dia AS dia_obs1,
	eut2.dia AS dia_last_obs,
	eut1.spcd AS spcd,
	rs.scientific_name, 
	rs.association
FROM tree_dates_and_harvested tdh
JOIN east_us_tree eut1
ON eut1.statecd = tdh.statecd
	AND eut1.unitcd = tdh.unitcd
	AND eut1.countycd = tdh.countycd
	AND eut1.plot = tdh.plot
	AND eut1.subp = tdh.subp
	AND eut1.tree = tdh.tree
	AND eut1.invyr = tdh.obs1
JOIN east_us_tree eut2
ON eut2.statecd = tdh.statecd
	AND eut2.unitcd = tdh.unitcd
	AND eut2.countycd = tdh.countycd
	AND eut2.plot = tdh.plot
	AND eut2.subp = tdh.subp
	AND eut2.tree = tdh.tree
	AND eut2.invyr = tdh.last_obs
JOIN ref_species rs
ON eut1.spcd = rs.spcd