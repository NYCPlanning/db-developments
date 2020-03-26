-- update the job_type field DCP's preffered values 
WITH jobtypelookup AS (
SELECT DISTINCT job_type,
	(CASE 
		WHEN job_type = 'A1' THEN 'Alteration'
		WHEN job_type = 'DM' THEN 'Demolition'
		WHEN job_type = 'NB' THEN 'New Building'
		ELSE job_type
	END ) AS type
FROM developments
)

UPDATE developments a
SET job_type = b.type
FROM jobtypelookup b
WHERE a.job_type=b.job_type;