/*
DESCRIPTION:
    This script assigns units fields for devdb
	1. Assign units_init and units_prop
	2. Apply corrections to units_init and units_prop
	3. Assign units_net

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
		hotel_init numeric,
		hotel_prop numeric,
		otherb_init numeric,
		otherb_prop numeric,
		units_net numeric
	)

IN PREVIOUS VERSION: 
    units_.sql
	units_net.sql
*/

DROP TABLE IF EXISTS _UNITS_devdb;
WITH
INIT_OCC_devdb as (
	SELECT 
		a.job_number,
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

-- Take manually-created class B and hotel unit fields from corrections file
UNITS_hotel_init AS (
	SELECT a.*, b.hotel_init
		FROM INIT_OCC_devdb a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as hotel_init
		FROM housing_input_research
		WHERE field = 'hotel_init'
		AND old_value IS NULL) b
		ON a.job_number = b.job_number
),

UNITS_hotel_prop AS (
	SELECT a.*, b.hotel_prop 
		FROM UNITS_hotel_init a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as hotel_prop
		FROM housing_input_research
		WHERE field = 'hotel_prop'
		AND old_value IS NULL) b
		ON a.job_number = b.job_number
),

UNITS_classb_init AS (
	SELECT a.*, b.otherb_init
		FROM UNITS_hotel_prop a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as otherb_init
		FROM housing_input_research
		WHERE field = 'otherb_init'
		AND old_value IS NULL) b
		ON a.job_number = b.job_number
),

UNITS_classb_prop AS (
	SELECT a.*, b.otherb_prop
		FROM UNITS_classb_init a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as otherb_prop
		FROM housing_input_research
		WHERE field = 'otherb_prop'
		AND old_value IS NULL) b
		ON a.job_number = b.job_number
),

UNITS_init_prop as (
	SELECT 
		job_number,
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
		END) as units_prop,
		hotel_init,
		hotel_prop,
		otherb_init,
		otherb_prop
	FROM UNITS_classb_prop
)

SELECT 
	distinct job_number,
	units_init,
	units_prop,
	hotel_init,
	hotel_prop,
	otherb_init,
	otherb_prop,
	job_type
INTO _UNITS_devdb
FROM UNITS_init_prop;

/*
CORRECTIONS

*/
-- units_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'units_init'
	AND (a.units_init=b.old_value::numeric 
		OR (a.units_init IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/units_init/',
	x_reason = x_reason||'/units_init:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET units_init = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_init'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/units_init/');

-- units_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'units_prop'
	AND (a.units_prop=b.old_value::numeric 
		OR (a.units_prop IS NULL 
		AND b.old_value IS NULL))
	AND a.job_number NOT IN (
		SELECT job_number 
		FROM housing_input_research 
		WHERE field = 'units_prop_res')
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/units_prop/',
	x_reason = x_reason||'/units_prop:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET units_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_prop'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/units_prop/');

/*
ASSIGN units_net
*/
DROP TABLE IF EXISTS UNITS_devdb;
SELECT 
	*,
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
FROM _UNITS_devdb;