-- Grab all AM trees with their yearly growth rates
SELECT statecd,
    unitcd, 
    countycd, 
    plot, 
    subp, 
    tree,
    harvested_on_obs1::varchar(5), 
    scientific_name, 
    association,
    ROUND(dia_last_obs::decimal - dia_obs1::decimal, 4) AS total_growth,
    years_elapsed,
    ROUND((dia_last_obs - dia_obs1)::decimal / years_elapsed::decimal, 4) AS growth_per_year
FROM growth
WHERE dia_last_obs IS NOT NULL
    AND association = 'AM'

-- Grab all EM trees with their yearly growth rates
SELECT statecd,
    unitcd, 
    countycd, 
    plot, 
    subp, 
    tree,
    harvested_on_obs1::varchar(5), 
    scientific_name, 
    association,
    ROUND(dia_last_obs::decimal - dia_obs1::decimal, 4) AS total_growth,
    years_elapsed,
    ROUND((dia_last_obs - dia_obs1)::decimal / years_elapsed::decimal, 4) AS growth_per_year
FROM growth
WHERE dia_last_obs IS NOT NULL
    AND association = 'EM'