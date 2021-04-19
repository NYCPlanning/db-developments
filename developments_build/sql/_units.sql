
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
SELECT DISTINCT
	a.job_number,
	a.job_type,
	b.occ_proposed,
	b.occ_initial,
	a.classa_init,
	a.classa_prop,
	(CASE
		WHEN a.job_type = 'New Building' THEN 0
		ELSE NULL
	END) as hotel_init,
	(CASE
		WHEN a.job_type = 'Demolition' THEN 0
		ELSE NULL
	END) as hotel_prop,
	(CASE
		WHEN a.job_type = 'New Building' THEN 0
		ELSE NULL
	END) as otherb_init,
	(CASE
		WHEN a.job_type = 'Demolition' THEN 0
		ELSE NULL
	END) as otherb_prop
INTO _UNITS_devdb
FROM INIT_devdb a
LEFT JOIN OCC_devdb b
ON a.job_number = b.job_number;


/*
CORRECTIONS
Note that hotel/otherb corrections match old_value with
the associated classa field. As a result, these corrections
get applied prior to the classa corrections.
*/

-- hotel_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'hotel_init'
	AND (a.classa_init=b.old_value::numeric 
		OR (a.classa_init IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'hotel_init')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET hotel_init = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'hotel_init'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'hotel_init'=any(dcpeditfields));

-- hotel_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number = b.job_number
	AND b.field = 'hotel_prop'
	AND (a.classa_prop = b.old_value::numeric 
		OR (a.classa_prop IS NULL 
		AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'hotel_prop')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET hotel_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'hotel_prop'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'hotel_prop'=any(dcpeditfields));

-- otherb_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'otherb_init'
	AND (a.classa_init=b.old_value::numeric 
		OR (a.classa_init IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'otherb_init')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET otherb_init = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'otherb_init'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'otherb_init'=any(dcpeditfields));

-- otherb_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _UNITS_devdb a, housing_input_research b
	WHERE a.job_number = b.job_number
	AND b.field = 'otherb_prop'
	AND (a.classa_prop = b.old_value::numeric 
		OR (a.classa_prop IS NULL 
		AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'otherb_prop')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _UNITS_devdb a
SET otherb_prop = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'otherb_prop'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'otherb_prop'=any(dcpeditfields));

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
SET dcpeditfields = array_append(dcpeditfields, 'classa_init')
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
	WHERE 'classa_init'=any(dcpeditfields));

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
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields, 'classa_prop')
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
	WHERE 'classa_prop'=any(dcpeditfields));

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