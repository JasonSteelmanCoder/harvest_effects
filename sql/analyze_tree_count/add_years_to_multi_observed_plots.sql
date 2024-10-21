-- add last_obs and years_elapsed to the plots and their harvest status 
CREATE TABLE multi_observed_plots_with_years_and_harvesting AS (
	SELECT 
		moph.statecd, 
		moph.unitcd, 
		moph.countycd, 
		moph.plot, 
		moph.obs1, 
		MAX(eup.invyr) AS last_obs,
		MAX(eup.invyr) - moph.obs1 AS years_elapsed,
		moph.harvested_at_obs1
	FROM multi_observed_plots_harvest_at_obs1 moph
	JOIN east_us_plot eup
	ON 
		eup.statecd = moph.statecd
		AND eup.unitcd = moph.unitcd
		AND eup.countycd = moph.countycd
		AND eup.plot = moph.plot
	GROUP BY 
		moph.statecd, 
		moph.unitcd, 
		moph.countycd, 
		moph.plot, 
		moph.obs1, 
		moph.harvested_at_obs1
)








