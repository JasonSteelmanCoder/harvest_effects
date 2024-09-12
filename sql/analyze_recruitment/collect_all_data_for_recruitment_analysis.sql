-- add tree counts to plot-dates-harvstatus

WITH with_first_obs AS (
	-- add the counts of AM, ECM, and Other trees to the plots for Obs1
	SELECT 
		moph.statecd, 
		moph.unitcd, 
		moph.countycd, 
		moph.plot, 
		moph.obs1, 
		moph.last_obs, 
		moph.years_elapsed, 
		moph.harvested_at_obs1,
		SUM(CASE WHEN rs.association = 'AM' THEN 1 ELSE 0 END) AS num_am_trees_obs1,
		SUM(CASE WHEN rs.association = 'EM' THEN 1 ELSE 0 END) AS num_em_trees_obs1,
		SUM(CASE WHEN (rs.association != 'AM' AND rs.association != 'EM') THEN 1 ELSE 0 END) AS num_other_trees_obs1
	FROM multi_observed_plots_with_years_and_harvesting moph
	LEFT JOIN east_us_tree eut1			-- join trees that were in each plot at obs1
	ON eut1.statecd = moph.statecd		
		AND eut1.unitcd = moph.unitcd
		AND eut1.countycd = moph.countycd
		AND eut1.plot = moph.plot
		AND eut1.invyr = moph.obs1
		AND eut1.statuscd = 1		-- don't count dead trees
	LEFT JOIN ref_species rs
	ON rs.spcd = eut1.spcd
	GROUP BY 
		moph.statecd, 
		moph.unitcd, 
		moph.countycd, 
		moph.plot, 
		moph.obs1, 
		moph.last_obs, 
		moph.years_elapsed, 
		moph.harvested_at_obs1
	ORDER BY num_other_trees_obs1 DESC
)
SELECT 
		wfo.statecd, 
		wfo.unitcd, 
		wfo.countycd, 
		wfo.plot, 
		wfo.obs1, 
		wfo.last_obs, 
		wfo.years_elapsed, 
		wfo.harvested_at_obs1,
		num_am_trees_obs1,
		num_em_trees_obs1,
		num_other_trees_obs1,
		SUM(CASE WHEN rs.association = 'AM' THEN 1 ELSE 0 END) AS num_am_trees_last_obs,
		SUM(CASE WHEN rs.association = 'EM' THEN 1 ELSE 0 END) AS num_em_trees_last_obs,
		SUM(CASE WHEN (rs.association != 'AM' AND rs.association != 'EM') THEN 1 ELSE 0 END) AS num_other_trees_last_obs
FROM with_first_obs wfo
LEFT JOIN east_us_tree eut2			-- join trees that were in each plot at last obs
ON eut2.statecd = wfo.statecd		
	AND eut2.unitcd = wfo.unitcd
	AND eut2.countycd = wfo.countycd
	AND eut2.plot = wfo.plot
	AND eut2.invyr = wfo.last_obs
	AND eut2.statuscd = 1		-- don't count dead trees
LEFT JOIN ref_species rs
ON rs.spcd = eut2.spcd
GROUP BY 
	wfo.statecd, 
	wfo.unitcd, 
	wfo.countycd, 
	wfo.plot, 
	wfo.obs1, 
	wfo.last_obs, 
	wfo.years_elapsed, 
	wfo.harvested_at_obs1,
	wfo.num_am_trees_obs1,
	wfo.num_em_trees_obs1,
	wfo.num_other_trees_obs1
ORDER BY num_other_trees_obs1 DESC








