/** QAQC
	invalid_date_lastupdt
	invalid_date_filed
	invalid_date_statusd
	invalid_date_statusp
	invalid_date_statusr
	invalid_date_statusx
**/


DROP TABLE IF EXISTS _QAQC_devdb;
WITH
-- identify invalid dates in input data
JOBNUMBER_invalid_dates AS (
	SELECT job_number,
		 (CASE WHEN is_date(date_lastupdt) 
		 		OR date_lastupdt IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_lastupdt,
		 (CASE WHEN is_date(date_filed) 
		 		OR date_filed IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_filed,
		 (CASE WHEN is_date(date_statusd) 
		 		OR date_statusd IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusd,
		 (CASE WHEN is_date(date_statusp) 
		 		OR date_statusp IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusp,
		 (CASE WHEN is_date(date_statusr)
		 		OR date_statusr IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusr,
		 (CASE WHEN is_date(date_statusx)
		 		OR date_statusx IS NULL THEN 0
		 	ELSE 1 END) as invalid_date_statusx
		FROM _INIT_devdb )
SELECT *
INTO _QAQC_devdb
FROM JOBNUMBER_invalid_dates;