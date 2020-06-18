/** QAQC
    z_inactive_with_update
**/

DROP TABLE IF EXISTS STATUS_qaqc;
WITH 
JOBNUMBER_inactive_update AS(
    SELECT job_number
    FROM STATUS_devdb
    WHERE date_lastupdt > :'CAPTURE_DATE_PREV'::date
    AND job_number IN (SELECT job_number
        FROM housing_input_research
        WHERE field = 'job_inactive'
        AND new_value = 'Inactive')
)

SELECT a.*,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_inactive_update) THEN 1
	 	ELSE 0
	END) as z_inactive_with_update
INTO STATUS_qaqc
FROM UNITS_qaqc a;