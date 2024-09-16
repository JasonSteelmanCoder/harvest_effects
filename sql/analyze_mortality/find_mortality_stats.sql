WITH mortality_data AS (
	WITH dying_plus_assoc AS (
		-- grab all dying trees along with their associations
		SELECT 
			dt.statecd, 
			dt.unitcd,
			dt.countycd,
			dt.plot,
			dt.subp,
			dt.tree,
			dt.spcd,
			dt.first_obs,
			dt.last_obs,
			dt.num_obs,
			dt.condid,
			rs.association
		FROM dying_trees dt
		JOIN ref_species rs
		ON rs.spcd = dt.spcd
	)
	-- gather everything necessary to perform analysis of mortality
	SELECT 
		dpa.statecd,
		dpa.unitcd,
		dpa.countycd,
		dpa.plot,
		dpa.subp,
		dpa.tree,
		dpa.association,
		euc.trtcd1,
		euc.trtcd2,
		euc.trtcd3,
		CASE WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN 'true' ELSE 'false' END AS harvested_at_obs1
	FROM dying_plus_assoc dpa
	JOIN east_us_cond euc
	ON 
		euc.invyr = dpa.first_obs
		AND euc.statecd = dpa.statecd
		AND euc.unitcd = dpa.unitcd
		AND euc.countycd = dpa.countycd
		AND euc.plot = dpa.plot
		AND euc.condid = dpa.condid
	WHERE euc.trtcd1 IS NOT NULL 
		AND euc.trtcd2 IS NOT NULL
		AND euc.trtcd3 IS NOT NULL
) 
-- get the count of dying trees that belong to each combination of association and harvesting status (excluding associations other than AM and EM)
SELECT harvested_at_obs1, association, COUNT(harvested_at_obs1) 
FROM mortality_data 
WHERE association = 'AM' OR association = 'EM'
GROUP BY harvested_at_obs1, association
