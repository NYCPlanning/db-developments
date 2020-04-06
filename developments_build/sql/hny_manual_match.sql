-- Insert manually research records into lookup table, only if the hny_id
-- exists in hny table and the pairs not exit in the lookup table.
-- If there are duplicates in hny_manual, insert the one which ranks front
-- ordering by dob_job_num_source alphabetically
WITH method AS(
    SELECT hny_id, MIN(dob_job_num_source) as method
    FROM hny_manual
    GROUP BY hny_id
    )
INSERT INTO hny_job_lookup (hny_id, job_number, match_method, dob_type)
SELECT hm.hny_id, hm.dob_job1, hm.dob_job_num_source, hm.dob_type
FROM hny_manual hm, method m
WHERE hm.hny_id = m.hny_id
AND hm.dob_job_num_source = m.method
AND hm.hny_id IN (
    SELECT hny_id
    FROM hny
    )
AND hm.hny_id NOT IN (
    SELECT hny_id
    FROM hny_job_lookup
    )
AND CONCAT(hm.hny_id,hm.dob_job1) NOT IN (
    SELECT CONCAT(hny_id,job_number)
    FROM hny_job_lookup
    )
;

-- Insert the dob_job2 from manually research table into lookup table, only if
-- a corresponding dob_job1 has been added in the last step 
-- and the match method is manualy review.
INSERT INTO hny_job_lookup (hny_id, job_number, match_method, dob_type)
SELECT hm.hny_id, hm.dob_job2, hm.dob_job_num_source, hm.dob_type
FROM hny_manual hm, hny_job_lookup l
WHERE hm.hny_id IN (
SELECT hny_id FROM hny_job_lookup)
AND (l.match_method = 'Amanda_Manual'
OR l.match_method = 'Bill_Manual')
AND hm.dob_job2 IS NOT NULL
AND hm.hny_id = l.hny_id;

-- Insert manually research records into lookup table, only if the hny_id
-- exists in hny table and the pairs not exit in the lookup table.
INSERT INTO hny_job_lookup (hny_id, job_number,match_method)
SELECT a.hny_id, a.job_number, 'DCP_Manual'
FROM housing_input_hny a
WHERE a.hny_id IN (
    SELECT hny_id
    FROM hny
    )
AND CONCAT(a.hny_id,a.job_number) NOT IN (
    SELECT CONCAT(hny_id,job_number)
    FROM hny_job_lookup
    )
AND a.hny_id IS NOT NULL
;

VACUUM ANALYZE hny_job_lookup;

-- update dob_type is NULL using developments_hny
WITH tmp AS(
		SELECT job_number, COUNT(*) FROM developments_hny
		GROUP BY job_number
		HAVING COUNT(*) = 1
	),
    _type AS(
	SELECT job_number, job_type FROM developments_hny
	WHERE job_number IN(
	 	SELECT job_number FROM tmp)
)
UPDATE hny_job_lookup l
SET dob_type = (CASE WHEN l.dob_type IS NULL THEN job_type
					 ELSE l.dob_type
				END)				
FROM _type t
WHERE l.job_number = t.job_number
;

VACUUM ANALYZE hny_job_lookup;

-- update dob_type format in lookup table
UPDATE hny_job_lookup
SET dob_type = (CASE WHEN dob_type = 'New Building' THEN 'NB'
					 WHEN dob_type = 'Alteration' THEN 'A1'
                     ELSE dob_type
				END);