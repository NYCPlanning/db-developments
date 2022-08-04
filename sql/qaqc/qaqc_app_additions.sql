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
