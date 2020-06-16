/*
DESCRIPTION:
    This script creates and recodes occupancy code for devdb
	1. Assign occ_proposed and occ_initial
	2. Apply corrections on occ_proposed and occ_initial
	3. Assign occ_category
	4. Apply corrections on occ_category

INPUTS:
    INIT_devdb (
        job_number text, 
        job_type text,
        _occ_initial text,
        _occ_proposed text,
    )
    
	occ_lookup (
		* dob_occ text,
		occ text
	)

OUTPUTS:
    OCC_devdb (
        * job_number text, 
        occ_initial text,
        occ_proposed text,
        resid_flag text,
        nonres_flag text
    )

IN PREVIOUS VERSION: 
    occ_.sql
*/

DROP TABLE IF EXISTS _OCC_devdb;
SELECT 
	job_number,
	job_desc, 
	occ_translate(_occ_initial, job_type) as occ_initial,
	occ_translate(_occ_proposed, job_type)  as occ_proposed
INTO _OCC_devdb
FROM INIT_devdb;

/*
CORRECTIONS
	occ_initial
	occ_proposed
*/

-- occ_initial
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _OCC_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'occ_initial'
	AND (a.occ_initial=b.old_value 
		OR (a.occ_initial IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'occ_initial'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'occ_initial', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _OCC_devdb a
SET occ_initial = b.new_value
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_initial'=any(x_dcpedited));

-- occ_proposed
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _OCC_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
	AND b.field = 'occ_proposed'
	AND (a.occ_proposed=b.old_value
		OR (a.occ_proposed IS NULL
		AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'occ_proposed'),
	x_reason = array_append(x_reason, json_build_object(
		'field', 'occ_proposed', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _OCC_devdb a
SET occ_proposed = TRIM(b.new_value)
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_proposed'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_proposed'=any(x_dcpedited));

/*
Assign occ_category after corrections on 
occ_initial and occ_proposed
*/
DROP TABLE IF EXISTS __OCC_devdb;
SELECT 
	*,
	(CASE 
		WHEN occ_initial ~* 'RESIDENTIAL' 
			OR occ_proposed ~* 'RESIDENTIAL'
			OR upper(occ_initial) LIKE '%ASSISTED%LIVING%' 
			OR upper(occ_proposed) LIKE '%ASSISTED%LIVING%'
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
	occ_initial,
	occ_proposed, 
	occ_category as resid_flag,
	flag_nonres(
		occ_category,
		job_desc,
		occ_initial,
		occ_proposed
	) as nonres_flag
INTO OCC_devdb
FROM __OCC_devdb;
DROP TABLE IF EXISTS __OCC_devdb;