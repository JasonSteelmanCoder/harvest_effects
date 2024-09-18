WITH plot_years AS (
	-- grab plot-years 
		-- aggregate trtcds from all of the conditions (remember that there may be more than one condition per plot)
		-- aggregate agg_trtcds1-3 into one yearly_trtcd
	SELECT 
		euc.statecd,
		euc.unitcd,
		euc.countycd,
		euc.plot,
		euc.invyr,
		MAX(CASE WHEN euc.trtcd1 = 10 THEN 10 ELSE 0 END) AS agg_trtcd1,
		MAX(CASE WHEN euc.trtcd2 = 10 THEN 10 ELSE 0 END) AS agg_trtcd2,
		MAX(CASE WHEN euc.trtcd3 = 10 THEN 10 ELSE 0 END) AS agg_trtcd3,
		CASE 
			WHEN (
				MAX(CASE WHEN euc.trtcd1 = 10 THEN 10 ELSE 0 END) = 10
				OR MAX(CASE WHEN euc.trtcd2 = 10 THEN 10 ELSE 0 END) = 10
				OR MAX(CASE WHEN euc.trtcd3 = 10 THEN 10 ELSE 0 END) = 10
			) 
			THEN 10 
			ELSE 0 
		END AS yearly_trtcd
	FROM east_us_cond euc
	WHERE 
		euc.trtcd1 IS NOT NULL
		AND euc.trtcd2 IS NOT NULL
		AND euc.trtcd3 IS NOT NULL
	GROUP BY
		euc.statecd,
		euc.unitcd,
		euc.countycd,
		euc.plot,
		euc.invyr
	ORDER BY 
		euc.statecd,
		euc.unitcd,
		euc.countycd,
		euc.plot,
		euc.invyr
)
-- grab all thrice-obserced plots with their list of obs_years and harvest codes
SELECT 
	py.statecd,
	py.unitcd,
	py.countycd,
	py.plot,
	ARRAY_AGG(py.invyr ORDER BY py.invyr) AS obs_years,
	ARRAY_AGG(py.yearly_trtcd ORDER BY py.invyr) AS trtcds
FROM plot_years py
GROUP BY 
	py.statecd,
	py.unitcd,
	py.countycd,
	py.plot
HAVING 
	ARRAY_LENGTH(ARRAY_AGG(py.invyr ORDER BY py.invyr), 1) > 2		-- only accept plots that are observed at least three times



-- still to account for: counts of am and em trees

