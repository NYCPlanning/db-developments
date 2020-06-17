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

DROP TABLE IF EXISTS OCC_devdb;
SELECT 
	job_number,
	occ_translate(_occ_initial, job_type) as occ_initial,
	occ_translate(_occ_proposed, job_type)  as occ_proposed
INTO OCC_devdb
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
	FROM OCC_devdb a, housing_input_research b
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

UPDATE OCC_devdb a
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
	FROM OCC_devdb a, housing_input_research b	
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

UPDATE OCC_devdb a
SET occ_proposed = TRIM(b.new_value)
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'occ_proposed'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'occ_proposed'=any(x_dcpedited));