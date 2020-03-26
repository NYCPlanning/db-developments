-- Append the geocode results to the housing_input_hny_job_manual
DROP TABLE IF EXISTS hny_manual;
SELECT a.*, b.geo_bbl, b.geo_bin INTO hny_manual
FROM housing_input_hny_job_manual a
LEFT JOIN hny_manual_geocode_results b
ON a.ogc_fid::text = b.uid;

-- Add unique id to the hny_manual table
ALTER TABLE hny_manual
    ADD hny_id text;
UPDATE hny_manual
SET hny_id = md5(CAST((project_id,
                       number,
                       street,
                       geo_bin,
                       geo_bbl) AS text));