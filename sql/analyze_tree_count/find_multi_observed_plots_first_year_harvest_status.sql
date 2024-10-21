-- find all multi-observed plots with non-null first treatment codes, their obs1 year, and their harvest_at_obs1 status
CREATE TABLE multi_observed_plots_harvest_at_obs1 AS (
	WITH plot_minyear_treatments AS (
		WITH multi_obs_plots AS (
			-- grab one instance of each plot that is observed more than once
			SELECT statecd, unitcd, countycd, plot, MIN(invyr) AS obs1, COUNT(invyr) AS num_obs
			FROM east_us_plot
			WHERE invyr != 9999
			GROUP BY statecd, unitcd, countycd, plot
			HAVING COUNT(invyr) > 1
			ORDER BY COUNT(invyr)
		)
		-- grab the first observation year and its treatment codes for each plot that is observed more than once 
		-- (keep in mind that there can be more than one condition on a plot in the same year)
		SELECT eup.statecd, eup.unitcd, eup.countycd, eup.plot, eup.invyr AS obs1, euc.trtcd1, euc.trtcd2, euc.trtcd3
		FROM east_us_plot eup
		JOIN east_us_cond euc
		ON
			eup.statecd = euc.statecd 
			AND eup.unitcd = euc.unitcd
			AND eup.countycd = euc.countycd
			AND eup.plot = euc.plot
			AND eup.invyr = euc.invyr
		JOIN multi_obs_plots mop
		ON 
			mop.obs1 = eup.invyr
			AND mop.statecd = eup.statecd
			AND mop.unitcd = eup.unitcd
			AND mop.countycd = eup.countycd
			AND mop.plot = eup.plot
		WHERE 
			(eup.statecd, eup.unitcd, eup.countycd, eup.plot) IN (SELECT statecd, unitcd, countycd, plot FROM multi_obs_plots)
			AND euc.trtcd1 IS NOT NULL
			AND euc.trtcd2 IS NOT NULL
			AND euc.trtcd3 IS NOT NULL
		GROUP BY eup.statecd, eup.unitcd, eup.countycd, eup.plot, eup.invyr, euc.trtcd1, euc.trtcd2, euc.trtcd3
		ORDER BY eup.statecd, eup.unitcd, eup.countycd, eup.plot
	)
	-- grab each plot, with booleans for harvesting in the first observation year
	SELECT pmt.statecd, pmt.unitcd, pmt.countycd, pmt.plot, pmt.obs1, BOOL_OR(trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10)::varchar(5) AS harvested_at_obs1
	FROM plot_minyear_treatments pmt
	GROUP BY pmt.statecd, pmt.unitcd, pmt.countycd, pmt.plot, pmt.obs1
	ORDER BY pmt.statecd, pmt.unitcd, pmt.countycd, pmt.plot, pmt.obs1
)

