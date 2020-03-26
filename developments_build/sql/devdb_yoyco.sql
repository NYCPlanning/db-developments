DROP TABLE IF EXISTS developments_yoyco;
SELECT * INTO developments_yoyco
FROM developments
WHERE ((co_earliest_effectivedate::date >= '2010-01-01' AND co_earliest_effectivedate::date <=  '2020-01-01')
OR (co_earliest_effectivedate IS NULL AND status_q::date >= '2010-01-01' AND status_q::date <=  '2020-01-01')
OR (co_earliest_effectivedate IS NULL AND status_q IS NULL AND status_a::date >= '2010-01-01' AND status_a::date <=  '2020-01-01'))
AND (occ_category = 'Residential' OR occ_prop LIKE '%Residential%' OR occ_init LIKE '%Residential%' OR occ_prop LIKE '%Assisted%Living%' OR occ_init LIKE '%Assisted%Living%')
AND (occ_init IS DISTINCT FROM 'Garage/Miscellaneous' OR occ_prop IS DISTINCT FROM 'Garage/Miscellaneous')
AND job_number NOT IN (
    SELECT DISTINCT job_number 
    FROM developments
    WHERE job_type = 'New Building' AND occ_prop = 'Hotel or Dormitory' AND x_mixeduse IS NULL)
AND x_outlier IS DISTINCT FROM 'true'
;