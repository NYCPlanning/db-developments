/* 
create the certificate of occupancy table
*/
DROP TABLE IF EXISTS INIT_devco;
WITH 
DRAFT_devco as (
    SELECT
        jobnum as job_number, 
        effectivedate,
        min(effectivedate::date) AS co_earliest_effectivedate,
        LEFT(min(effectivedate::date)::text,4) AS year_complete,
        max(effectivedate::date) AS co_latest_effectivedate,
        numofdwellingunits::numeric as co_latest_units,
        certificatetype as co_latest_certtype
    FROM dob_cofos
    WHERE jobnum IN (
        SELECT DISTINCT job_number
        FROM INIT_devdb)
),
ASSIGN_multi_co as (
    SELECT 
        job_number,
        effectivedate,
        co_earliest_effectivedate,
        year_complete,
        co_latest_effectivedate,
        co_latest_units,
        'C- CO' as co_latest_certtype
	FROM DRAFT_devco
	WHERE co_latest_effectivedate::date = effectivedate::date
	GROUP BY job_number
	HAVING count(*) > 1
)
SELECT 
    job_number,
    effectivedate,
    co_earliest_effectivedate,
    year_complete,
    co_latest_effectivedate,
    co_latest_units,
    co_latest_certtype
INTO INIT_devco
FROM (
    SELECT *
    FROM ASSIGN_multi_co
    UNION
    SELECT *
    FROM DRAFT_devco
    WHERE job_number not in (
        SELECT DISTINCT job_number 
        FROM ASSIGN_multi_co)
) a;