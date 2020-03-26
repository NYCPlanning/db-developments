-- QAQC for pairs which are many-to-many
-- DELETE Records not existing in manual research table
WITH manual AS (
    WITH lookup AS (
        SELECT * FROM hny_job_lookup
        WHERE one_to_many_flag = '1-to-many'
        AND many_to_one_flag = 'many-to-1'
        )
    SELECT hm.hny_id, hm.dob_job1
    FROM hny_manual hm, lookup l
    WHERE hm.hny_id = l.hny_id
    AND hm.dob_job1 = l.job_number
)
DELETE FROM hny_job_lookup
WHERE one_to_many_flag = '1-to-many'
AND many_to_one_flag = 'many-to-1'
AND (CONCAT(hny_id, job_number) NOT IN(
    SELECT CONCAT(hny_id, dob_job1)
    FROM manual
    )
AND CONCAT(hny_id, job_number) NOT IN(
    SELECT CONCAT(hny_id, job_number)
    FROM housing_input_hny
    )
)
;

-- Assign value to the one_many_flag (hny_job_relat) after QAQC
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

-- Assign value to the one_many_flag (hny_job_relat) after QAQC				
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


-- Assign aggregated hny_job_relat value
UPDATE hny_job_lookup
SET hny_to_job_relat = (CASE 
                            WHEN one_to_many_flag = '1-to-1' AND many_to_one_flag = '1-to-1'
                                THEN '1-to-1'
						    WHEN one_to_many_flag = '1-to-many' AND many_to_one_flag = '1-to-1'
                                THEN '1-to-many'
                            WHEN one_to_many_flag = '1-to-1' AND many_to_one_flag = 'many-to-1'
                                THEN 'many-to-1'
                            WHEN one_to_many_flag = '1-to-many' AND many_to_one_flag = 'many-to-1'
                                THEN 'many-to-many'
					    END);

-- DROP fields one_to_many_flag and many_to_one_flag
ALTER TABLE hny_job_lookup
DROP one_to_many_flag,
DROP many_to_one_flag;