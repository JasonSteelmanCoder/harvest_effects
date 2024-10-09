-- get the distribution of timespans (the timespan being the number of years from the first observation of a plot to the last observation of that plot)
WITH min_max AS (
	SELECT 
		(SELECT MAX(year) FROM UNNEST(year_sequence) AS year) AS max_year,
		(SELECT MIN(year) FROM UNNEST(year_sequence) AS year) AS min_year
	FROM a_temp
)
SELECT 
	max_year - min_year AS timespan, 
	COUNT(max_year - min_year) AS frequency
FROM min_max
GROUP BY max_year - min_year
ORDER BY (max_year - min_year) DESC


-- check how many times plots have been observed
SELECT 
	ARRAY_LENGTH(cn_sequence, 1) AS num_observations,
	COUNT(ARRAY_LENGTH(cn_sequence, 1)) AS num_plots
FROM a_temp
GROUP BY ARRAY_LENGTH(cn_sequence, 1)
ORDER BY ARRAY_LENGTH(cn_sequence, 1) DESC;


