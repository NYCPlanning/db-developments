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
WITH manual_hny_match_check AS (
    SELECT 
    job_number
    FROM corr_hny_matches 
    WHERE 
    action = 'add' 
    AND
    hny_id IN (SELECT hny_id FROM hny_no_match)
)
UPDATE qaqc_app_additions 
SET manual_hny_match_check = (
    CASE 
        WHEN qaqc_app_additions.job_number NOT IN (SELECT job_number FROM manual_hny_match_check) THEN 0 
        ELSE 1 
    END);

ALTER TABLE qaqc_app_additions ADD manual_corrections_not_applied INT;
UPDATE qaqc_app_additions
SET manual_corrections_not_applied=(
    CASE 
        WHEN qaqc_app_additions.job_number IN (SELECT job_number FROM corrections_not_applied) THEN 1 ELSE 0 
    END);
