-- create output file for GRU research
DROP TABLE IF EXISTS qc_millionbinresearch;
CREATE TABLE qc_millionbinresearch AS (
SELECT job_number, job_type, bin as dob_bin, geo_bin
FROM developments
WHERE RIGHT(geo_bin,6)= '000000')
ORDER BY job_number;

-- drop million pseudo BINS from the geo_bin field
UPDATE developments
SET geo_bin = NULL
WHERE RIGHT(geo_bin,6)= '000000';