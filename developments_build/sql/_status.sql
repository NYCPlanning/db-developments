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
        complete_year text,
        complete_qrtr text,
        co_latest_units numeric,
        co_latest_certtype text,
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
        classa_net numeric,
        address text,
        occ_proposed text,
        job_inactive text,
        dcpeditfields text
    )

IN PREVIOUS VERSION: 
    status.sql
    year_complete.sql
    unitscomplete.sql
*/
DROP TABLE IF EXISTS STATUS_devdb;
WITH
DRAFT_STATUS_devdb as (
    SELECT
        a.job_number,
        a.job_type,
        CASE
            WHEN a.x_withdrawal IN ('W', 'C')
                        THEN '9. Withdrawn'
            WHEN a.job_type IN ('New Building', 'Alteration')
                        AND a.co_latest_certtype = 'T- TCO'
                        AND a.classa_complt_pct < 0.8 
                        AND a.classa_net >= 20
                        THEN '4. Partially Completed Construction'
            WHEN a.date_complete IS NOT NULL THEN '5. Completed Construction'
            WHEN a.date_statusr IS NOT NULL THEN '3. Permitted for Construction'
            WHEN a.date_permittd IS NOT NULL THEN '3. Permitted for Construction'
            WHEN a.date_statusp IS NOT NULL THEN '2. Approved Application'
            WHEN b.assigned IS NOT NULL THEN '1. Filed Application'
            WHEN a.date_statusd IS NOT NULL THEN '1. Filed Application'
            WHEN b.paid IS NOT NULL THEN '1. Filed Application'
            WHEN a.date_filed IS NOT NULL THEN '1. Filed Application'	
            ELSE NULL
        END as job_status,
        a.date_permittd,
        a.date_lastupdt::date,
        a.classa_init,
        a.classa_prop,
        a.classa_net,
        a.address,
        a.occ_proposed,
        a.date_complete,
        a.complete_year,
        a.complete_qrtr
    FROM _MID_devdb a
    JOIN dob_jobapplications b
    ON a.job_number::int = b.jobnumber::int
)
SELECT
    distinct
    job_number,
    job_type,
    job_status,
    date_lastupdt,
    date_permittd,
    complete_year,
    complete_qrtr,
    classa_init,
    classa_prop,
    classa_net,
    address,
    occ_proposed,
    -- Set inactive flag
    (CASE 
        -- All withdrawn jobs are inactive
        WHEN job_status = '9. Withdrawn'
            THEN 'Inactive'
        -- A date_complete indicates not inactive
        WHEN date_complete IS NOT NULL 
            THEN NULL
        -- Jobs not (partially) complete that haven't been updated in 3 years
        WHEN (:'CAPTURE_DATE'::date - date_lastupdt)/365 >= 3 
            AND job_status IN ('1. Filed Application', 
                                '2. Approved Application', 
                                '3. Permitted for Construction')
            THEN 'Inactive'
    END) as job_inactive
INTO STATUS_devdb
FROM DRAFT_STATUS_devdb;

-- Jobs matching with a newer, (partially) complete job get set to inactive
WITH completejobs AS (
	SELECT address, job_type, date_lastupdt, job_status, classa_init, classa_prop
	FROM STATUS_devdb
	WHERE classa_init IS NOT NULL
    AND classa_prop IS NOT NULL
	AND job_status IN ('4. Partially Completed Construction', '5. Completed Construction'))
UPDATE STATUS_devdb a 
SET job_inactive = 'Inactive'
FROM completejobs b
WHERE a.job_status IN ('1. Filed Application', '2. Approved Application', '3. Permitted for Construction')
	AND a.job_type = b.job_type
    AND a.address = b.address
    AND a.classa_init = b.classa_init
    AND a.classa_prop = b.classa_prop
	AND a.date_lastupdt::date < b.date_lastupdt::date;

/* 
CORRECTIONS
    job_inactive
*/
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
SET dcpeditfields = array_append(dcpeditfields, 'job_inactive')
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
	WHERE 'job_inactive'=any(dcpeditfields));
