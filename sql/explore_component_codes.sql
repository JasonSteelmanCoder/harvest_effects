WITH indiv_trees AS (
	SELECT 
		mot.original_cn,
		UNNEST(mot.cn_sequence) AS current_cn
	FROM east_us_multi_observed_trees mot
)
SELECT 
	it.*,
	dia_begin,
	grm.micr_component_al_forest,
	subp_component_al_forest,
	subp_component_gs_forest,
	subp_component_sl_forest,
	micr_component_al_timber,
	subp_component_al_timber,
	subp_component_gs_timber,
	subp_component_sl_timber
FROM indiv_trees it
JOIN east_us_tree_grm_component grm
ON grm.tre_cn = it.current_cn
WHERE dia_begin >= 5
ORDER BY dia_begin DESC




