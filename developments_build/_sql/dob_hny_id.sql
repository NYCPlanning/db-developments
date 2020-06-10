-- Add new fields
ALTER TABLE developments_hny
    ADD hny_id text,
    ADD hny_to_job_relat text,
    ADD all_hny_units text,
    ADD affordable_units text;

-- Insert values to new fields from hny_job_lookup table
-- In the case where a job_number matches multiple hny unique ids,
-- Assign the smallest hny_id to that job_number
WITH hny_unique AS (
    SELECT job_number, MIN(hny_id) as hny_id
    FROM hny_job_lookup
    GROUP BY job_number
    )
UPDATE developments_hny d
SET hny_id = l.hny_id,
    hny_to_job_relat = l.hny_to_job_relat
FROM hny_job_lookup l, hny_unique u
WHERE l.hny_id = u.hny_id
AND l.job_number = u.job_number
AND d.job_number = l.job_number;