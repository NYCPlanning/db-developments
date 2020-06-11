/*
DESCRIPTION:
    This script is created to assign/recode the field "status" 
    
INPUTS:
    MID_devdb (
        * job_number,
        job_type character varying,
        status_date date,
        status_p date,
        status_q date,
        _status text,
        year_complete text,
        quarter_complete text,
        co_latest_units numeric,
        co_latest_certtype text,
        units_complete numeric,
        units_incomplete numeric,
        units_net numeric,
        address text,
        occ_prop text
    )

    housing_input_lookup_status (
        dobstatus,
        dcpstatus
    )

OUTPUTS:
    STATUS_devdb (
        * job_number character varying,
        job_type character varying,
        status character varying,
        status_date date,
        status_q date,
        year_complete text,
        quarter_complete text,
        units_complete numeric,
        units_incomplete numeric,
        units_net numeric,
        address text,
        occ_prop text,
        x_inactive text,
        x_dcpedited text,
        x_reason text
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
        a.status_q,
        a.year_complete,
        a.quarter_complete,
        a.units_net,
        a.co_latest_units,
        a.status_date,
        a.address,
        a.occ_prop,
        (CASE
            WHEN a.job_type = 'New Building'
                AND a.co_latest_certtype = 'T- TCO'
                AND (
                    (a.units_complete_pct < 0.8 AND a.units_net >= 20) OR 
                    (a.units_complete_diff >= 5 AND a.units_net BETWEEN 5 AND 19)
                )
                THEN '4. Partial Complete'

            WHEN a.job_type = 'Demolition' 
                AND b.status IN ('5. Complete','3. Permited') 
                THEN '5. Complete'

            WHEN a.x_withdrawal IN ('W', 'C')
                THEN '9. Withdrawn'

            WHEN status_p IS NOT NULL
                THEN '2. Plan Examination'

            WHEN status_q IS NOT NULL
                THEN '3. Permited'

            ELSE b.status 
        END) as status
    FROM MID_devdb a
    LEFT JOIN status_lookup b
    ON a._status = b.dob_status
),
DRAFT_STATUS_devdb as (
    SELECT
        job_number,
        job_type,
        status,
        status_q,
        status_date::date,
        units_net,
        address,
        occ_prop,
        -- update year_compelete based on job_type and status
        (CASE
            WHEN job_type = 'Demolition'
                OR status NOT IN ('4. Partial Complete', '5. Complete')
                THEN NULL
            ELSE year_complete
        END) as year_complete,

        -- update quarter_compelete based on job_type and status
        (CASE
            WHEN job_type = 'Demolition'
                OR status NOT IN ('4. Partial Complete', '5. Complete')
                THEN NULL
            ELSE quarter_complete
        END) as quarter_complete,

        -- Assign units_complete based on status
        (CASE
            WHEN status = '5. Complete' 
                THEN units_net
            WHEN status = '4. Partial Complete' 
                THEN co_latest_units
            ELSE NULL
        END) as units_complete,

        -- Assing units_incomplete
        (CASE
            WHEN status = '5. Complete' 
                THEN NULL
            WHEN status = '4. Partial Complete'
                THEN units_net-co_latest_units
            ELSE units_net
        END) units_incomplete
    FROM STATUS_translate
)
SELECT
    job_number,
    job_type,
    status,
    status_date,
    status_q,
    year_complete,
    units_complete,
    units_incomplete,
    units_net,
    address,
    occ_prop,
    (CASE 
        WHEN (CURRENT_DATE - status_date)/365 >= 2 
            AND status = '2. Plan Examination'
            THEN 'Inactive'
        WHEN (CURRENT_DATE - status_date)/365 >= 3 
            AND status in ('1. Filed', '2. Plan Examination')
            THEN 'Inactive'
        WHEN status = '9. Withdrawn'
            THEN 'Inactive'
    END) as x_inactive
INTO STATUS_devdb
FROM DRAFT_STATUS_devdb;

WITH completejobs AS (
	SELECT address, job_type, status_date, status
	FROM STATUS_devdb
	WHERE units_net::numeric > 0
	AND status = '5. Complete')
UPDATE STATUS_devdb a 
SET x_inactive = 'Inactive'
FROM completejobs b
WHERE a.address = b.address
	AND a.job_type = b.job_type
	AND a.status != '5. Complete'
	AND a.status_date::date < b.status_date::date
	AND a.status <> '9. Withdrawn'
  	AND a.occ_prop <> 'Garage/Miscellaneous';

/* 
CORRECTIONS
    units_complete
    units_incomplete
    x_inactive
*/
-- units_complete
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'units_complete'
    AND (a.units_complete=b.old_value::numeric 
        OR (a.units_complete IS NULL
            AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/units_complete/',
	x_reason = x_reason||'/units_complete:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET units_complete = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_complete'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/units_complete/');
        
-- units_incomplete
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'units_incomplete'
    AND (a.units_incomplete=b.old_value::numeric 
        OR (a.units_incomplete IS NULL
            AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/units_complete/',
	x_reason = x_reason||'/units_complete:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET units_incomplete = b.new_value::numeric
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_incomplete'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/units_incomplete/');

-- x_inactive
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason
	FROM STATUS_devdb a, housing_input_research b	
	WHERE a.job_number=b.job_number
    AND b.field = 'x_inactive'
    AND (upper(a.x_inactive)=upper(b.old_value) 
        OR (a.x_inactive IS NULL 
            AND (b.old_value IS NULL 
            OR b.old_value = 'false')))
)
UPDATE CORR_devdb a
SET x_dcpedited = x_dcpedited||'/x_inactive/',
	x_reason = x_reason||'/x_inactive:'||b.reason
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE STATUS_devdb a
SET x_inactive = trim(b.new_value)
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'x_inactive'
AND a.job_number in (
	SELECT DISTINCT job_number
	FROM CORR_devdb
	WHERE x_dcpedited ~* '/x_inactive/');