/* 
DESCRIPTION:
    create the certificate of occupancy table using dof_cofos

INPUTS: 
    dob_cofos (
        jobnum,
        effectivedate,
        numofdwellingunits,
        certificatetype
    )

    INIT_devdb (
        job_number
    )

OUTPUTS: 
    CO_devdb (
        job_number text,
        effectivedate date,
        co_earliest_effectivedate date,
        year_complete text,
        co_latest_effectivedate date,
        co_latest_units numeric,
        co_latest_certtype text
    )

IN PREVIOUS VERSION: 
    cotable.sql
    co_.sql
*/
DROP TABLE IF EXISTS CO_devdb;
WITH 
DRAFT_co as (
    SELECT
        jobnum as job_number, 
        effectivedate::date,
        numofdwellingunits::numeric as co_latest_units,
        certificatetype as co_latest_certtype
    FROM dob_cofos
    WHERE jobnum IN (
        SELECT DISTINCT job_number
        FROM INIT_devdb)
),
DATES_co as (
    SELECT
        b.*,
        a.co_earliest_effectivedate,
        a.year_complete,
        a.co_latest_effectivedate
    FROM ( 
        SELECT 
            job_number, 
            min(effectivedate::date) AS co_earliest_effectivedate,
            LEFT(min(effectivedate::date)::text,4) AS year_complete,
            max(effectivedate::date) AS co_latest_effectivedate
        FROM DRAFT_co
        GROUP BY job_number
    ) a
    LEFT JOIN DRAFT_co b
    ON a.job_number=b.job_number
),
MULTI_co_jobs as (
    SELECT 
        job_number
	FROM DATES_co
	WHERE co_latest_effectivedate = effectivedate
	GROUP BY job_number
	HAVING count(*) > 1
)
SELECT *
INTO CO_devdb
FROM (
    SELECT 
        job_number,
        effectivedate,
        co_earliest_effectivedate,
        year_complete,
        co_latest_effectivedate,
        co_latest_units,
        'C- CO' as co_latest_certtype
    FROM DATES_co
    WHERE job_number in (
        SELECT DISTINCT job_number 
        FROM MULTI_co_jobs)
    UNION
    SELECT 
		job_number,
		effectivedate,
		co_earliest_effectivedate,
		year_complete,
		co_latest_effectivedate,
		co_latest_units,
		co_latest_certtype
    FROM DATES_co
    WHERE job_number not in (
        SELECT DISTINCT job_number 
        FROM MULTI_co_jobs)
) a;