WITH t1_tree_observations AS (
	-- grab all of the tree observations that happened after a plot's first observation, but before the plot's first harvest
	-- number the observations of individual trees (to help count distinct trees instead of observations)
	SELECT 
		ROW_NUMBER() OVER (
			PARTITION BY original_tree_cn
			ORDER BY current_year
		) AS during_t1_tree_obs_number,
		original_tree_cn,
		association,
		statuscd,
		death_year,
		obs_number,
		current_year,
		first_plot_obs_year,
		last_pre_harvest_year,
		first_harvest_year,
		last_plot_obs_year, 
		original_plot_cn,
		current_plot_cn
	FROM a_temp 
	WHERE 
		current_year > first_plot_obs_year		-- t1 trees are observed *after* the first plot observation
		AND current_year < first_harvest_year		-- t1 trees are observed before the first harvest observation
),

t1_plots AS (
	SELECT 
		COUNT(original_tree_cn) AS t1_population, 
		first_plot_obs_year,
		last_pre_harvest_year, 
		first_harvest_year,
		last_plot_obs_year,
		original_plot_cn
	FROM t1_tree_observations
	WHERE during_t1_tree_obs_number = 1		-- prevent duplicates for trees observed twice before harvesting
	GROUP BY 
		first_plot_obs_year,
		last_pre_harvest_year,
		first_harvest_year,
		last_plot_obs_year,
		original_plot_cn
	ORDER BY 
		original_plot_cn 
),

t2_tree_observations AS (
	-- grab all of the tree observations that happened after a plot's first harvest observation
	-- number the observations of individual trees (to help count distinct trees instead of observations)
	SELECT 
		ROW_NUMBER() OVER (
			PARTITION BY original_tree_cn
			ORDER BY current_year
		) AS during_t2_tree_obs_number,
		original_tree_cn,
		association,
		statuscd,
		death_year,
		obs_number,
		current_year,
		first_plot_obs_year,
		last_pre_harvest_year,
		first_harvest_year,
		last_plot_obs_year, 
		original_plot_cn,
		current_plot_cn
	FROM a_temp 
	WHERE 
		current_year > first_harvest_year		-- t2 trees are observed *after* the first harvest observation
),

t2_plots AS (
	SELECT 
		COUNT(original_tree_cn) AS t2_population, 
		first_plot_obs_year,
		last_pre_harvest_year, 
		first_harvest_year,
		last_plot_obs_year,
		original_plot_cn
	FROM t2_tree_observations
	WHERE during_t2_tree_obs_number = 1		-- prevent duplicates for trees observed twice before harvesting
	GROUP BY 
		first_plot_obs_year,
		last_pre_harvest_year,
		first_harvest_year,
		last_plot_obs_year,
		original_plot_cn
	ORDER BY 
		original_plot_cn 	
)
--
SELECT * 
FROM t2_plots

	