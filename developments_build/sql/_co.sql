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
ORDER_co as (
    SELECT
        jobnum as job_number, 
        effectivedate::date as effectivedate,
        numofdwellingunits::numeric as units, 
        certificatetype as certtype,
		ROW_NUMBER() OVER (
			PARTITION BY jobnum
			ORDER BY effectivedate::date DESC) as latest,
		ROW_NUMBER() OVER (
			PARTITION BY jobnum
			ORDER BY effectivedate::date ASC) as earliest,
		DENSE_RANK() OVER (
			PARTITION BY jobnum
			ORDER BY effectivedate::date DESC) as multi
    FROM dob_cofos
    WHERE jobnum IN (
        SELECT DISTINCT job_number
        FROM INIT_devdb)
),
DRAFT_co as (
	SELECT
		a.*,
		b.co_earliest_effectivedate
	FROM (
		SELECT
			job_number, 
			effectivedate as co_latest_effectivedate,
			units as co_latest_units,
			certtype as co_latest_certtype
		FROM ORDER_co
		WHERE latest = 1
	) a
	LEFT JOIN (
		SELECT 
			job_number, 
			effectivedate as co_earliest_effectivedate
		FROM ORDER_co
		WHERE earliest = 1
	) b ON a.job_number = b.job_number
)
SELECT 
    job_number,
    co_earliest_effectivedate,
    co_latest_effectivedate,
    co_latest_units,
    co_latest_certtype,
    extract(year from co_earliest_effectivedate)::text as year_complete
INTO CO_devdb
FROM DRAFT_co;