WITH individual_trees_with_spcd AS (
	WITH individual_trees AS (
		WITH prepped_observations AS (
			WITH conditioned_trees AS (
				WITH conditions AS (
					WITH measured_trees AS (
						WITH multi_obs_trees AS (
							-- find each observation of every multi-observed tree
							SELECT 
								eumot.original_cn,
								UNNEST(eumot.cn_sequence) AS current_cn
							FROM east_us_multi_observed_trees eumot
							WHERE ARRAY_LENGTH(eumot.cn_sequence, 1) > 2		-- accept only plots that were observed at least 3x
						)
						-- add diameter, year, and plot from the tree table
						-- only keep live trees, with valid diameters
						SELECT 
							mot.*,
							eut.dia,
							eut.invyr,
							eut.plt_cn, 
							eut.spcd
						FROM multi_obs_trees mot
						JOIN east_us_tree eut
						ON eut.cn = mot.current_cn
						WHERE eut.dia IS NOT NULL
							AND eut.statuscd = 1
					)
					-- add harvest codes from the cond table
					-- REMEMBER: one plot can have more than one condition! Each row in this table is a *condition* on the plot where the tree is.
					SELECT
						mt.*,
						CASE WHEN trtcd1 IS NULL THEN NULL WHEN (trtcd1 = 10 OR trtcd2 = 10 OR trtcd3 = 10) THEN 10 ELSE 0 END AS harvested
					FROM measured_trees mt
					JOIN east_us_cond euc
					ON euc.plt_cn = mt.plt_cn
				)
				-- group back into individual tree observations, making the harvest codes for each condition into an array
				SELECT 
					cnd.original_cn, 
					cnd.current_cn, 
					cnd.dia, 
					cnd.invyr, 
					cnd.plt_cn,
					cnd.spcd,
					ARRAY_AGG(harvested ORDER BY harvested) AS harvest_conditions
				FROM conditions cnd
				GROUP BY original_cn, current_cn, dia, invyr, plt_cn, spcd
			)
			-- consolidate harvest conditions into one indicator per tree observation
			-- if harvest conditions has a 10, keep a 10 (we know there's harvesting there). if it doesn't have a 10, but does have a null, keep null (there could be harvesting that we don't know about). if it's all zeros, keep 0.
			SELECT 
				original_cn, 
				current_cn,
				dia,
				invyr,
				plt_cn,
				spcd,
				harvest_conditions,
				CASE WHEN 10 = ANY(harvest_conditions) THEN 10 WHEN ARRAY_POSITION(harvest_conditions, NULL) IS NOT NULL THEN NULL ELSE 0 END AS harvested
			FROM conditioned_trees ct
		)
		-- group all observations back into individual trees
		SELECT 
			po.original_cn,
			ARRAY_AGG(po.current_cn ORDER BY invyr) AS cn_sequence,
			ARRAY_AGG(po.plt_cn ORDER BY invyr) AS plt_cn,
			spcd,
			ARRAY_AGG(po.dia ORDER BY invyr) AS dia,
			ARRAY_AGG(po.invyr ORDER BY invyr) AS invyr,
			ARRAY_AGG(po.harvested ORDER BY invyr) AS harvested
		FROM prepped_observations po
		GROUP BY original_cn, spcd
	)
	-- only keep trees that were unharvested on their first observation and harvested before the final observation
	SELECT 
		it.*
	FROM individual_trees it
	WHERE it.harvested[1] = 0
		AND 10 = ANY(it.harvested[2:ARRAY_LENGTH(harvested, 1) - 1])
	ORDER BY ARRAY_LENGTH(cn_sequence, 1) DESC
)
-- convert spcd to association
SELECT 
	itws.original_cn, 
	itws.cn_sequence,
	itws.plt_cn, 
	rs.association,
	itws.dia,
	itws.invyr,
	itws.harvested
FROM individual_trees_with_spcd itws
JOIN ref_species rs
ON rs.spcd = itws.spcd




