/*
DESCRIPTION:
    This script creates and recodes occupancy code for devdb
	1. Assign occ_prop and occ_init
	2. Apply corrections on occ_prop and occ_init
	3. Assign occ_category
	4. Apply corrections on occ_category

INPUTS:
    INIT_devdb (
        job_number text, 
        job_type text,
        _occ_init text,
        _occ_prop text,
    )
    
	occ_lookup (
		* dob_occ text,
		occ text
	)

OUTPUTS:
    OCC_devdb (
        * job_number text, 
        occ_init text,
        occ_prop text,
        occ_category text
    )

IN PREVIOUS VERSION: 
    occ_.sql
*/

DROP TABLE IF EXISTS _OCC_devdb;
SELECT 
	job_number,
	job_description, 
	occ_translate(_occ_init, job_type) as occ_init,
	occ_translate(_occ_prop, job_type)  as occ_prop
INTO _OCC_devdb
FROM INIT_devdb;

/*
CORRECTIONS
	occ_init
	occ_prop
*/

-- occ_init
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _OCC_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'occ_init'
	AND (a.occ_init=b.old_value 
		OR (a.occ_init IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'occ_init'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'occ_init', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _OCC_devdb a
SET occ_init = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_init'=any(x_dcpedited));

-- occ_prop
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _OCC_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
	AND b.field = 'occ_prop'
	AND (a.occ_prop=b.old_value
		OR (a.occ_prop IS NULL
		AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'occ_prop'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'occ_prop', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _OCC_devdb a
SET occ_prop = TRIM(b.new_value)
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_prop'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_prop'=any(x_dcpedited));

/*
Assign occ_category after corrections on 
occ_init and occ_prop
*/
DROP TABLE IF EXISTS __OCC_devdb;
SELECT 
	*,
	(CASE 
		WHEN occ_init ~* 'RESIDENTIAL' 
			OR occ_prop ~* 'RESIDENTIAL'
			OR upper(occ_init) LIKE '%ASSISTED%LIVING%' 
			OR upper(occ_prop) LIKE '%ASSISTED%LIVING%'
			THEN 'Residential'
		ELSE NULL
	END) as occ_category
INTO __OCC_devdb
FROM _OCC_devdb;

/*
CORRECTIONS
	occ_category
*/

-- occ_category
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM __OCC_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
	AND b.field = 'occ_category'
	AND (a.occ_category=b.old_value 
		OR (a.occ_category IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'occ_category'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'occ_category', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE __OCC_devdb a
SET occ_category = NULLIF(TRIM(b.new_value), 'Other')
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_category'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_category'=any(x_dcpedited));

-- Assign Nonresid flag
DROP TABLE IF EXISTS OCC_devdb;
SELECT
	job_number,
	occ_init,
	occ_prop, 
	occ_category as resid_flag,
	flag_nonresid(
		occ_category,
		job_description,
		occ_init,
		occ_prop
	) as nonresid
INTO OCC_devdb
FROM __OCC_devdb;
DROP TABLE IF EXISTS __OCC_devdb;