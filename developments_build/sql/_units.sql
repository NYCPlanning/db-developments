/*
DESCRIPTION:
    This script assigns units fields for devdb
	1. Assign classa_init and classa_prop
	2. Apply corrections to classa_init and classa_prop
	3. Assign classa_net

INPUTS: 
	INIT_devdb (
		job_number text,
		job_type text,
		_classa_init numeric,
		_classa_prop numeric,
		x_mixeduse text
	)

	OCC_devdb (
		job_number text,
		occ_initial text,
		occ_proposed text
	)

OUTPUTS:
	UNITS_devdb (
		job_number text, 
		classa_init numeric,
		classa_prop numeric,
		hotel_init numeric,
		hotel_prop numeric,
		otherb_init numeric,
		otherb_prop numeric,
		classa_net numeric
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
		b.occ_proposed,
		b.occ_initial,
		a._classa_init,
		a._classa_prop,
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
				then nullif(_classa_init, 0) 
			WHEN job_type='Alteration' 
				AND occ_initial ~* 'hotel'
				AND occ_proposed ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _classa_init
		END) as classa_init, 
		(CASE
			WHEN job_type='Demolition' 
				then nullif(_classa_prop, 0) 
			WHEN job_type='Alteration' 
				AND occ_initial ~* 'hotel'
				AND occ_proposed ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _classa_prop
		END) as classa_prop,
		hotel_init,
		hotel_prop,
		otherb_init,
		otherb_prop
	FROM UNITS_classb_prop
)

SELECT 
	distinct job_number,
	classa_init,
	classa_prop,
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
-- classa_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'classa_init'
	AND (a.classa_init=b.old_value::numeric 
		OR (a.classa_init IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited, 'classa_init'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'classa_init', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET classa_init = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'classa_init'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'classa_init'=any(x_dcpedited));

-- classa_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number = b.job_number
	AND b.field = 'classa_prop'
	AND (a.classa_prop = b.old_value::numeric 
		OR (a.classa_prop IS NULL 
		AND b.old_value IS NULL))
	AND a.job_number NOT IN (
		SELECT job_number 
		FROM housing_input_research 
		WHERE field = 'units_prop_res')
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited, 'classa_prop'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'classa_prop', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET classa_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'classa_prop'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'classa_prop'=any(x_dcpedited));

/*
ASSIGN classa_net
*/
DROP TABLE IF EXISTS UNITS_devdb;
SELECT
	*,
	(CASE
		WHEN job_type = 'Demolition' 
			THEN classa_init * -1
		WHEN job_type = 'New Building' 
			THEN classa_prop
		WHEN job_type = 'Alteration' 
			AND classa_init IS NOT NULL 
			AND classa_prop IS NOT NULL 
			THEN classa_prop - classa_init
		ELSE NULL
	END) as classa_net
INTO UNITS_devdb
FROM _UNITS_devdb;