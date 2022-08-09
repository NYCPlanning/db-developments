DROP TABLE IF EXISTS qaqc_app_additions;
WITH 
classa_net_mismatch AS (
    SELECT job_number
    FROM FINAL_devdb
    WHERE
    classa_init IS NOT NULL
    AND classa_prop IS NOT NULL
    AND classa_net <> classa_prop - classa_init
)
SELECT a.job_number,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM classa_net_mismatch) THEN 1
	 	ELSE 0
	END) as classa_net_mismatch
INTO qaqc_app_additions
FROM FINAL_devdb a;

ALTER TABLE qaqc_app_additions ADD manual_hny_match_check INT;
WITH manual_hny_match_check AS (SELECT 
job_number
FROM corr_hny_matches 
WHERE 
action = 'add' 
AND
hny_id IN (SELECT hny_id FROM hny_no_match)
)
UPDATE qaqc_app_additions 
SET manual_hny_match_check = 1
FROM qaqc_app_additions q, manual_hny_match_check m
WHERE q.job_number = m.job_number;

UPDATE qaqc_app_additions
SET manual_hny_match_check=(CASE WHEN manual_hny_match_check=1 THEN 1 ELSE 0 END);