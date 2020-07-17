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
	CLASSA_devdb (
		job_number text, 
		classa_init numeric,
		classa_prop numeric,
		classa_net numeric
	)

IN PREVIOUS VERSION: 
    units_.sql
	units_net.sql
*/

DROP TABLE IF EXISTS _CLASSA_devdb;
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
)
SELECT 
	distinct 
	job_number,
	job_type,
	classa_init,
	classa_prop
INTO _CLASSA_devdb
FROM INIT_OCC_devdb;

/*
CORRECTIONS

*/
-- classa_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _CLASSA_devdb a, housing_input_research b
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

UPDATE _CLASSA_devdb a
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
	FROM _CLASSA_devdb a, housing_input_research b
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

UPDATE _CLASSA_devdb a
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
DROP TABLE IF EXISTS CLASSA_devdb;
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
INTO CLASSA_devdb
FROM _CLASSA_devdb;