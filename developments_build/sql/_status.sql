/*
DESCRIPTION:
    This script is created to assign/recode the field "job_status" 
    
INPUTS:
    _MID_devdb (
        * job_number,
        job_type character varying,
        date_lastupdt date,
        date_statusp date,
        date_permittd date,
        _job_status text,
        _complete_year text,
        _complete_qrtr text,
        co_latest_units numeric,
        co_latest_certtype text,
        classa_complt numeric,
        classa_incmpl numeric,
        classa_net numeric,
        address text,
        occ_proposed text
    )

    housing_input_lookup_status (
        dobstatus,
        dcpstatus
    )

OUTPUTS:
    STATUS_devdb (
        * job_number character varying,
        job_type character varying,
        job_status character varying,
        date_lastupdt date,
        date_permittd date,
        complete_year text,
        complete_qrtr text,
        classa_complt numeric,
        classa_incmpl numeric,
        classa_net numeric,
        address text,
        occ_proposed text,
        job_inactive text,
        x_dcpedited text,
        dcpeditfields text
    )

IN PREVIOUS VERSION: 
    status.sql
    year_complete.sql
    unitscomplete.sql
*/
DROP TABLE IF EXISTS STATUS_devdb;
WITH
STATUS_translate as (
    SELECT 
        a.job_number,
        a.job_type,
        a.date_permittd,
        a._complete_year,
        a._complete_qrtr,
        a.classa_net,
        a.co_latest_units,
        a.date_lastupdt,
        a.address,
        a.occ_proposed,
        a.date_complete,

        (CASE
            WHEN a.job_type = 'New Building'
                AND a.co_latest_certtype = 'T- TCO'
                AND (
                    (a.classa_complt_pct < 0.8 AND a.classa_net >= 20) OR 
                    (a.classa_complt_diff >= 5 AND a.classa_net BETWEEN 5 AND 19)
                )
                THEN '4. Partial Complete'

            WHEN a.job_type = 'Demolition'
                AND date_statusx IS NOT NULL
                THEN '5. Complete'

            WHEN a.x_withdrawal IN ('W', 'C')
                THEN '9. Withdrawn'

            WHEN date_statusp IS NOT NULL
                THEN '2. Plan Examination'

            WHEN date_permittd IS NOT NULL
                THEN '3. Permited'

            ELSE status_translate(a._job_status)
        END) as job_status
    FROM _MID_devdb a
),
DRAFT_STATUS_devdb as (
    SELECT
        job_number,
        job_type,
        job_status,
        date_permittd,
        date_lastupdt::date,
        classa_net,
        address,
        occ_proposed,
        date_complete,
        -- update year_compelete based on job_type and status
        (CASE
            WHEN job_type = 'Demolition'
                OR job_status NOT IN ('4. Partial Complete', '5. Complete')
                THEN NULL
            ELSE _complete_year
        END) as complete_year,

        -- update complete_qrtr based on job_type and job_status
        (CASE
            WHEN job_type = 'Demolition'
                OR job_status NOT IN ('4. Partial Complete', '5. Complete')
                THEN NULL
            ELSE _complete_qrtr
        END) as complete_qrtr,

        -- Assign classa_complt based on job_status
        (CASE
            WHEN job_status = '5. Complete' 
                THEN classa_net
            WHEN job_status = '4. Partial Complete' 
                THEN co_latest_units
            ELSE NULL
        END) as classa_complt,

        -- Assing classa_incmpl
        (CASE
            WHEN job_status = '5. Complete' 
                THEN NULL
            WHEN job_status = '4. Partial Complete'
                THEN classa_net-co_latest_units
            ELSE classa_net
        END) classa_incmpl
    FROM STATUS_translate
)
SELECT
    job_number,
    job_type,
    job_status,
    date_lastupdt,
    date_permittd,
    complete_year,
    complete_qrtr,
    classa_complt,
    classa_incmpl,
    classa_net,
    address,
    occ_proposed,
    (CASE 
        WHEN date_complete IS NOT NULL 
            THEN NULL
        WHEN (CURRENT_DATE - date_lastupdt)/365 >= 2 
            AND job_status = '2. Plan Examination'
            THEN 'Inactive'
        WHEN (CURRENT_DATE - date_lastupdt)/365 >= 3 
            AND job_status in ('1. Filed', '2. Plan Examination')
            THEN 'Inactive'
        WHEN job_status = '9. Withdrawn'
            THEN 'Inactive'
    END) as job_inactive
INTO STATUS_devdb
FROM DRAFT_STATUS_devdb;

WITH completejobs AS (
	SELECT address, job_type, date_lastupdt, job_status
	FROM STATUS_devdb
	WHERE classa_net::numeric > 0
	AND job_status = '5. Complete')
UPDATE STATUS_devdb a 
SET job_inactive = 'Inactive'
FROM completejobs b
WHERE a.address = b.address
	AND a.job_type = b.job_type
	AND a.job_status <> '5. Complete'
	AND a.date_lastupdt::date < b.date_lastupdt::date
	AND a.job_status <> '9. Withdrawn'
  	AND a.occ_proposed <> 'Garage/Miscellaneous';

/* 
CORRECTIONS
    classa_complt
    classa_incmpl
    job_inactive
*/
-- classa_complt
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
        b.edited_date
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'classa_complt'
    AND (a.classa_complt=b.old_value::numeric 
        OR (a.classa_complt IS NULL
            AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited, 'classa_complt'),
	dcpeditfields = array_append(dcpeditfields, json_build_object(
		'field', 'classa_complt', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET classa_complt = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'classa_complt'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'classa_complt'=any(x_dcpedited));
        
-- classa_incmpl
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
        b.edited_date
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'classa_incmpl'
    AND (a.classa_incmpl=b.old_value::numeric 
        OR (a.classa_incmpl IS NULL
            AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited,'classa_incmpl'),
	dcpeditfields = array_append(dcpeditfields, json_build_object(
		'field', 'classa_incmpl', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET classa_incmpl = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'classa_incmpl'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'classa_incmpl'=any(x_dcpedited));

-- job_inactive
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
        b.edited_date
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'job_inactive'
    AND (upper(a.job_inactive)=upper(b.old_value) 
        OR (a.job_inactive IS NULL 
            AND (b.old_value IS NULL 
            OR b.old_value = 'false')))
)
UPDATE CORR_devdb a
SET x_dcpedited = array_append(x_dcpedited, 'job_inactive'),
	dcpeditfields = array_append(dcpeditfields, json_build_object(
		'field', 'job_inactive', 'reason', b.reason, 
		'edited_date', b.edited_date
	))
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET job_inactive = trim(b.new_value)
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'job_inactive'
AND a.job_number in (
	SELECT DISTINCT job_number
	FROM CORR_devdb
	WHERE 'job_inactive'=any(x_dcpedited));