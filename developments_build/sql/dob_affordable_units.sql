-- Update affordable housing units for records having 1-to-1 or 1-to-many hny to job relationship
-- In the case when one hny_id matches multiple job_numbers,
-- Assign the hny affordable units to the smallest job_number
WITH total AS(
    WITH relat AS (
        SELECT hny_id, MIN(job_number) AS job_number
        FROM developments_hny
        WHERE hny_to_job_relat = '1-to-many'
        OR hny_to_job_relat = '1-to-1'
        GROUP BY hny_id
        )
    SELECT h.job_number, h.all_counted_units, h.total_units
    FROM hny h, relat r
    WHERE h.hny_id = r.hny_id
    AND h.job_number = r.job_number
    )
UPDATE developments_hny d
SET affordable_units = t.all_counted_units,
    all_hny_units = t.total_units
FROM total t
WHERE d.job_number = t.job_number
;


-- Update affordable housing units for records with many-to-1 hny_to_job_relat
-- In the case where one job_number matches multiple hny_ids
-- Assign the aggregated affordable units associated with that job_number
WITH total AS(
    WITH relat AS (
        SELECT *
        FROM developments_hny
        WHERE hny_to_job_relat = 'many-to-1'
        )
    SELECT h.job_number, 
        SUM(h.all_counted_units::NUMERIC) AS total_affordable_units,
        SUM(h.total_units::NUMERIC) AS total_all_hny_units
    FROM hny h, relat r
    WHERE h.job_number = r.job_number
    GROUP BY h.job_number
    )
UPDATE developments_hny d
SET affordable_units = t.total_affordable_units,
    all_hny_units = t.total_all_hny_units
FROM total t
WHERE d.job_number = t.job_number
;