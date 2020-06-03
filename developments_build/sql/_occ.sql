/*
DESCRIPTION:
    This script creates and recodes occupancy code for devdb

    occ_init 
        1. recoding using housing_input_lookup_occupancy
        2. Identify Garage/Miscellaneous jobs

    occ_prop
        1. recoding using housing_input_lookup_occupancy
        2. Identify Garage/Miscellaneous jobs

    occ_category
        1. assign 'Residential' or 'Other' absed 
        on text search on "occ_init" and "occ_prop"

	DEPENDS ON:
		create.sql

INPUTS:
    INIT_devdb (
        job_number text, 
        job_type text,
        job_description text,
        status_a text,
        _occ_init text,
        _occ_prop text,
        _units_prop numeric, 
        address text
    )
    housing_input_lookup_occupancy (
        doboccupancycode2008 text,
        doboccupancycode1968 text,
        dcpclassificationnew text
    )

OUTPUTS:
    OCC_devdb (
        job_number text, 
        occ_init text,
        occ_prop text,
        occ_category text
    )

IN PREVIOUS VERSION: 
    occ_.sql
*/

DROP TABLE IF EXISTS OCC_devdb;
WITH 
OCC_init_translate as (
	SELECT 
		DISTINCT a.job_number, 
		(CASE 
			WHEN a.job_type = 'New Building'
				THEN 'Empty Lot'
			WHEN right(status_a,4)::numeric >= 2008
				THEN coalesce(occ_init08, occ_init68)
			WHEN right(status_a,4)::numeric < 2008
				THEN coalesce(occ_init68, occ_init08)
			ELSE NULL
		END) as occ_init
	FROM (
		SELECT
			a.*,
			b.dcpclassificationnew as occ_init68
		FROM (
			SELECT
				a.job_number, 
				a.job_type,
				a.status_a,
				a._occ_init,
				b.dcpclassificationnew as occ_init08
			FROM INIT_devdb a
			LEFT join housing_input_lookup_occupancy b
			ON a._occ_init = b.doboccupancycode2008) a
		JOIN housing_input_lookup_occupancy b
		ON a._occ_init = b.doboccupancycode1968
	) a
),
OCC_prop_translate as (
	SELECT 
		DISTINCT a.job_number, 
		(CASE
			WHEN a.job_type = 'Demolition'
				THEN 'Empty Lot'
			WHEN right(status_a,4)::numeric >= 2008
				THEN coalesce(occ_prop08, occ_prop68)
			WHEN right(status_a,4)::numeric < 2008
				THEN coalesce(occ_prop68, occ_prop08)
			ELSE NULL
		END) as occ_prop
	FROM (
		SELECT 
			a.*, 
			b.dcpclassificationnew as occ_prop68
		FROM (
			SELECT 
				a.job_number,
				a.job_type,
				a.status_a, 
				a._occ_prop,
				b.dcpclassificationnew as occ_prop08
			FROM INIT_devdb a
			LEFT join housing_input_lookup_occupancy b
			ON a._occ_prop = b.doboccupancycode2008) a
		JOIN housing_input_lookup_occupancy b
		ON a._occ_prop = b.doboccupancycode1968
	) a
), 
OCC_init_garage as (
	SELECT
		DISTINCT job_number,
		'Garage/Miscellaneous' as occ_init
	FROM INIT_devdb 
	WHERE job_type = 'Alteration|Demolition'
	AND (job_description ~* 'GARAGE' 
		 	OR address ~* 'REAR')
),
OCC_prop_garage as (
	SELECT 
		DISTINCT job_number,
		'Garage/Miscellaneous' as occ_prop
	FROM (
		-- Alteration jobs with "garage" in job_description 
		-- or rear in address are labeled as "Garage/Miscellaneous"
		SELECT job_number
		FROM INIT_devdb 
		WHERE job_type = 'Alteration'
		AND (job_description ~* 'GARAGE' OR address ~* 'REAR')
		UNION

		-- New Building jobs with job_description that mention "garage"
		-- but not any other keywords that indicates residential units
		-- are labeled as "Garage/Miscellaneous"
		SELECT job_number
		FROM INIT_devdb
		WHERE job_type = 'New Building'
		AND job_description ~* 'GARAGE'
		AND job_description !~* 'RES|DWELL|HOUSE|HOME|APART|FAMILY'
		UNION


		-- For any address that has any new building jobs with 
		-- "Garage" in job_description, only label the jobs with 
		-- "Garage" in job_description as "Garage/Miscellaneous"
		SELECT job_number
		FROM INIT_devdb
		WHERE address||'-'||_units_prop::text in (
			SELECT DISTINCT address||'-'||_units_prop::text
			FROM INIT_devdb
			WHERE job_type = 'New Building'
			AND job_description !~* 'garage'
		) AND job_description ~* 'garage'
	) a
),
OCC_init_prop as (
	SELECT DISTINCT a.job_number, a.occ_init, b.occ_prop
	FROM (
		SELECT a.job_number, b.occ_init
		FROM INIT_devdb a
		LEFT JOIN (
			SELECT job_number, occ_init FROM OCC_init_garage
			UNION
			SELECT job_number, occ_init FROM OCC_init_translate
			WHERE job_number not in (SELECT job_number FROM OCC_init_garage)
		) b
		ON a.job_number = b.job_number
	) a
	LEFT JOIN (
		SELECT job_number, occ_prop FROM OCC_prop_garage
		UNION
		SELECT job_number, occ_prop FROM OCC_prop_translate
		WHERE job_number not in (SELECT job_number FROM OCC_prop_garage)
	) b
	ON a.job_number = b.job_number
)
SELECT 
	DISTINCT job_number,
	occ_init,
	occ_prop,
	(CASE 
		WHEN occ_init ~* 'RESIDENTIAL' 
			OR occ_prop ~* 'RESIDENTIAL'
			OR upper(occ_init) LIKE '%ASSISTED%LIVING%' 
			OR upper(occ_prop) LIKE '%ASSISTED%LIVING%'
			THEN 'Residential'
		ELSE 'Other'
	END) as occ_category
INTO OCC_devdb
FROM OCC_init_prop;