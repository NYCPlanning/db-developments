
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
		classa_init numeric,
		classa_prop numeric
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
		a.classa_init,
		a.classa_prop
	FROM INIT_devdb a
	LEFT JOIN OCC_devdb b
	ON a.job_number = b.job_number
),
RESEARCH_raw as (
	SELECT * FROM housing_input_research
	WHERE field in (
		'hotel_init', 'hotel_prop', 'otherb_init', 'otherb_prop')
),
RESEARCH as (
	SELECT 
		job_number, 
		(SELECT old_value from RESEARCH_RAW where field='hotel_init' and job_number=a.job_number)::numeric as hotel_init_old,
		(SELECT new_value from RESEARCH_RAW where field='hotel_init' and job_number=a.job_number)::numeric as hotel_init,
		(SELECT old_value from RESEARCH_RAW where field='hotel_prop' and job_number=a.job_number)::numeric as hotel_prop_old,
		(SELECT new_value from RESEARCH_RAW where field='hotel_prop' and job_number=a.job_number)::numeric as hotel_prop,
		(SELECT old_value from RESEARCH_RAW where field='otherb_init' and job_number=a.job_number)::numeric as otherb_init_old,
		(SELECT new_value from RESEARCH_RAW where field='otherb_init' and job_number=a.job_number)::numeric as otherb_init,
		(SELECT old_value from RESEARCH_RAW where field='otherb_prop' and job_number=a.job_number)::numeric as otherb_prop_old,
		(SELECT new_value from RESEARCH_RAW where field='otherb_prop' and job_number=a.job_number)::numeric as otherb_prop
	FROM (SELECT DISTINCT job_number FROM RESEARCH_RAW) a
),
-- Take manually-created class B and hotel unit fields from corrections file
UNITS_hotel_classb AS (
	SELECT 
		a.*, 
		(CASE WHEN b.hotel_init_old = a.classa_init
			THEN b.hotel_init END) as hotel_init,
		(CASE WHEN b.hotel_prop_old = a.classa_prop
			THEN b.hotel_prop END) as hotel_prop,
		(CASE WHEN b.otherb_init_old = a.classa_init
			THEN b.otherb_init END) as otherb_init,
		(CASE WHEN b.otherb_prop_old = a.classa_prop
			THEN b.otherb_prop END) as otherb_prop
	FROM INIT_OCC_devdb a 
	LEFT JOIN RESEARCH b 
	ON a.job_number = b.job_number
)
SELECT 
	distinct
	job_number,
	job_type,
	classa_init,
	classa_prop,
	hotel_init,
	hotel_prop,
	otherb_init,
	otherb_prop
INTO _UNITS_devdb
FROM UNITS_hotel_classb;

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
	dcpeditfields = array_append(dcpeditfields, json_build_object(
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
	dcpeditfields = array_append(dcpeditfields, json_build_object(
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