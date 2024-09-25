WITH trees AS (
	WITH obs_with_harvested AS (
		WITH obs_with_year AS (
			WITH obs_with_spcd AS (
				WITH measured_observations AS (
					WITH observations AS (
						-- grab each observation, labeled with the first cn that was given to the tree
						SELECT 
							original_cn, 
							UNNEST(cn_sequence) AS observation_cn
						FROM east_us_multi_observed_trees
					)
					-- grab the plot and growth for each observation
					SELECT 
						obs.*,
						grm.plt_cn,
						grm.ann_dia_growth
					FROM observations obs
					JOIN east_us_tree_grm_component grm
					ON obs.observation_cn = grm.tre_cn
				)
				-- grab species and condition id from east_us_tree
				SELECT 
					mo.*,
					eut.spcd,
					eut.condid
				FROM measured_observations mo
				JOIN east_us_tree eut
				ON mo.observation_cn = eut.cn
			)
			-- add the measurement year from the plot table
			SELECT 
				ows.*,
				eup.measyear
			FROM obs_with_spcd ows
			JOIN east_us_plot eup
			ON eup.cn = ows.plt_cn
		)
		-- add harvested codes from east_us_cond.trtcd1-3
		SELECT 
			owy.*,
			CASE WHEN (euc.trtcd1 = 10 OR euc.trtcd2 = 10 OR euc.trtcd3 = 10) THEN 10 ELSE 0 END AS harvested
		FROM obs_with_year owy
		JOIN east_us_cond euc
		ON euc.plt_cn = owy.plt_cn
			AND euc.condid = owy.condid 
	)	
	-- group into individual trees, with lists of details for each observation
	SELECT 
		owh.original_cn,
		ARRAY_AGG(owh.observation_cn ORDER BY owh.measyear) AS observation_cns,
		ARRAY_AGG(owh.plt_cn ORDER BY owh.measyear) AS plt_cns,
		ARRAY_AGG(owh.ann_dia_growth ORDER BY owh.measyear) AS ann_dia_growths,
		ARRAY_AGG(owh.condid ORDER BY owh.measyear) AS condids,
		ARRAY_AGG(owh.measyear ORDER BY owh.measyear) AS measyears,
		ARRAY_AGG(owh.harvested ORDER BY owh.measyear) AS harvested,
		MAX(owh.spcd) AS spcd
	FROM obs_with_harvested owh
	GROUP BY original_cn
	ORDER BY original_cn
)
-- add mycorrhizal association from ref_species
SELECT 
	trees.*,
	rs.association
FROM trees
LEFT JOIN ref_species rs
ON trees.spcd = rs.spcd



