/*
DESCRIPTION:
    This script is created to assign/recode the field "date_permittd" 

INPUTS: 
    INIT_devdb (
        job_number,
        job_type,
        _job_status,
        x_withdrawal,
        date_statusp,
        date_permittd
    )

    dob_permitissuance (
        jobnum,
        issuancedate
    )

OUTPUTS:
    STATUS_Q_devdb (
        job_number text,
        date_permittd date,
        permit_year text,
        permit_qrtr text
    )

*/
DROP TABLE IF EXISTS _STATUS_Q_devdb;
CREATE TABLE _STATUS_Q_devdb as (
    SELECT 
        jobnum as job_number, 
        min(issuancedate::date) as date_permittd
    FROM dob_permitissuance
    WHERE jobdocnum = '01'
    AND jobtype ~* 'A1|DM|NB'
    GROUP BY jobnum
);

/*
CORRECTIONS: 
    date_permittd
*/
WITH CORR_target as (
	SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _STATUS_Q_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
	AND b.field = 'date_permittd'
	AND (a.date_permittd::date = b.old_value::date
		OR (a.date_permittd IS NULL 
			AND b.old_value IS NULL))
)
UPDATE CORR_devdb a
SET dcpeditfields = array_append(dcpeditfields,'date_permittd')
FROM CORR_target b
WHERE a.job_number=b.job_number;

UPDATE _STATUS_Q_devdb a
SET date_permittd = b.new_value::date
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'date_permittd'
AND a.job_number in (
	SELECT DISTINCT job_number 
	FROM CORR_devdb
	WHERE 'date_permittd'=any(dcpeditfields));

/*
COMPUTE year_permit, quarter_permit
*/
DROP TABLE IF EXISTS STATUS_Q_devdb;
SELECT 
    a.job_number,
    b.date_permittd,
    -- year_permit
    extract(year from b.date_permittd)::text as permit_year,
    -- quarter_permit
    year_quarter(b.date_permittd) as permit_qrtr
INTO STATUS_Q_devdb
FROM INIT_devdb a
LEFT JOIN _STATUS_Q_devdb b
ON a.job_number = b.job_number;
