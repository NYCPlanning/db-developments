-- Assign value to the one_many_flag (hny_job_relat)
WITH relat AS (
    SELECT hny_id, COUNT(*) AS num_jobs FROM hny_job_lookup
    GROUP BY hny_id
    )
UPDATE hny_job_lookup l
SET one_to_many_flag = (CASE WHEN r.num_jobs >1 THEN '1-to-many'
							 WHEN r.num_jobs =1 THEN '1-to-1'
						END)
FROM relat r
WHERE l.hny_id = r.hny_id;

-- Assign value to the one_many_flag (hny_job_relat)					
WITH relat AS (
    SELECT job_number, COUNT(*) AS num_hnys FROM hny_job_lookup
    GROUP BY job_number
    )
UPDATE hny_job_lookup l
SET many_to_one_flag = (CASE WHEN r.num_hnys >1 THEN 'many-to-1'
							 WHEN r.num_hnys =1 THEN '1-to-1'
						END)
FROM relat r
WHERE l.job_number = r.job_number;