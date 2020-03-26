-- For any records that share an identical job_number and BBL, 
-- keep only the record with the most recent date_lastupdt value and remove the older record(s).
WITH latest AS (
	SELECT job_number, geo_bbl, MAX(status_date::DATE) AS date_lastupdt
	FROM developments
	GROUP BY job_number, geo_bbl
	HAVING COUNT(*)>1
)
DELETE FROM developments a
USING latest b
WHERE a.job_number = b.job_number
AND a.geo_bbl = b.geo_bbl
AND a.status_date::DATE != b.date_lastupdt
;

-- job_number and bbl combinations that needs to be dropped
DELETE FROM developments a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'bbl'
AND a.geo_bbl = b.old_value
AND b.new_value IS NULL;