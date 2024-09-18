WITH tree_years_and_treatments AS (
	-- grab one instance of each triple-observed tree, aggregating an array of the years when it was observed and an array of treatments corresponding to those years
	SELECT 
		eut.statecd,
		eut.unitcd,
		eut.countycd,
		eut.plot,
		eut.subp,
		eut.tree,
		ARRAY_AGG(eut.invyr ORDER BY eut.invyr) AS obs_years,
		ARRAY_AGG(euc.trtcd1 ORDER BY euc.invyr) AS trtcd1_array,
		ARRAY_AGG(euc.trtcd2 ORDER BY euc.invyr) AS trtcd2_array,
		ARRAY_AGG(euc.trtcd3 ORDER BY euc.invyr) AS trtcd3_array
	FROM east_us_tree eut
	JOIN east_us_cond euc
	ON 
		eut.condid = euc.condid
		AND eut.invyr = euc.invyr
		AND eut.statecd = euc.statecd
		AND eut.unitcd = euc.unitcd
		AND eut.countycd = euc.countycd
		AND eut.plot = euc.plot
	WHERE 
		eut.statuscd = 1				-- only accept live trees
		AND euc.trtcd1 IS NOT NULL		-- only accept years where trtcds were recorded
		AND euc.trtcd2 IS NOT NULL
		AND euc.trtcd3 IS NOT NULL
	GROUP BY 
		eut.statecd,
		eut.unitcd,
		eut.countycd,
		eut.plot,
		eut.subp,
		eut.tree
	HAVING 
		ARRAY_LENGTH(ARRAY_AGG(eut.invyr ORDER BY eut.invyr), 1) > 2 	-- only take triple-observed trees
)
-- grab all of the triple-obs trees that aren't harvested on obs1, but are harvested in one of their middle observations
SELECT 
	statecd,
	unitcd,
	countycd,
	plot,
	subp,
	tree,
	obs_years,
	ARRAY(
		SELECT CASE 
			WHEN trtcd1_array[i] = 10 OR trtcd2_array[i] = 10 OR trtcd3_array[i] = 10 THEN 10
			ELSE 0
		END
		FROM GENERATE_SUBSCRIPTS(trtcd1_array, 1) AS i
	) AS combined_trtcds
FROM tree_years_and_treatments tyat
WHERE 
	tyat.trtcd1_array[1] != 10				-- the plot was *not* harvested at obs1
	AND tyat.trtcd2_array[1] != 10
	AND tyat.trtcd3_array[1] != 10
	AND (									-- one of the *middle* trtcd's shows harvesting
		10 = ANY(tyat.trtcd1_array[2:ARRAY_LENGTH(trtcd1_array, 1) - 1])
		OR 10 = ANY(tyat.trtcd2_array[2:ARRAY_LENGTH(trtcd2_array, 1) - 1])
		OR 10 = ANY(tyat.trtcd3_array[2:ARRAY_LENGTH(trtcd3_array, 1) - 1])
	)

-- still to account for: need to grab first, last, and harvest years with associations and diameters