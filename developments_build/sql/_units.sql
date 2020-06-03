/*
DESCRIPTION:
    This script assigns units fields for devdb

    units_init 

    units_prop

    units_net   

	DEPENDS ON:
		 _occ.sql

INPUTS: 
	INIT_devdb (
		job_number text,
		job_type text,
		_units_init numeric,
		_units_prop numeric,
		x_mixeduse text
	)

	OCC_devdb (
		job_number text,
		occ_init text,
		occ_prop text
	)

OUTPUTS:
	UNITS_devdb (
		job_number text, 
		units_init numeric,
		units_prop numeric,
		units_net numeric
	)

IN PREVIOUS VERSION: 
    units_.sql
	units_net.sql
*/

DROP TABLE IF EXISTS UNITS_devdb;
WITH
INIT_OCC_devdb as (
	SELECT 
		distinct a.job_number,
		a.job_type,
		b.occ_prop,
		b.occ_init,
		a._units_init,
		a._units_prop,
		a.x_mixeduse
	FROM INIT_devdb a
	LEFT JOIN OCC_devdb b
	ON a.job_number = b.job_number
),
UNITS_init_prop as (
	SELECT 
		distinct job_number,
		job_type,
		(CASE 
			WHEN job_type='New Building' 
				then nullif(_units_init, 0) 
			WHEN job_type='Alteration' 
				AND occ_init ~* 'hotel'
				AND occ_prop ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _units_init
		END) as units_init, 
		(CASE
			WHEN job_type='Demolition' 
				then nullif(_units_prop, 0) 
			WHEN job_type='Alteration' 
				AND occ_init ~* 'hotel'
				AND occ_prop ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _units_prop
		END) as units_prop
	FROM INIT_OCC_devdb
)
SELECT 
	distinct job_number,
	units_init,
	units_prop,
	(CASE
		WHEN job_type = 'Demolition' 
			THEN units_init * -1
		WHEN job_type = 'New Building' 
			THEN units_prop
		WHEN job_type = 'Alteration' 
			AND units_init IS NOT NULL 
			AND units_prop IS NOT NULL 
			THEN units_prop - units_init
		ELSE NULL
	END) as units_net
INTO UNITS_devdb
FROM UNITS_init_prop;