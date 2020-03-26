-- Add new fields
ALTER TABLE hny
    ADD job_number text,
    ADD dob_type text,
    ADD hny_to_job_relat text;

-- Insert values to new fields from hny_job_lookup table
-- In the case where a hny_id matches multiple job numbers,
-- Assign the smallest job_number to that hny_id
WITH job AS(
    SELECT hny_id, MIN(job_number) as job_number
    FROM hny_job_lookup
    GROUP BY hny_id
    )
UPDATE hny h
SET job_number = l.job_number,
	dob_type = l.dob_type,
    hny_to_job_relat = l.hny_to_job_relat
FROM hny_job_lookup l, job j
WHERE l.hny_id = j.hny_id
AND l.job_number = j.job_number
AND h.hny_id = l.hny_id;

-- Create hny table with unmatched records
DROP TABLE IF EXISTS hny_job_unmatch;
SELECT * INTO hny_job_unmatch 
FROM hny
WHERE job_number IS NULL;