/*
DESCRIPTION:
    This script is created to assign/recode the field "date_permittd" 

INPUTS: 
    INIT_devdb (
        job_number
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
DROP TABLE IF EXISTS STATUS_Q_devdb;
WITH 
STATUS_Q_create as (
    SELECT 
        jobnum as job_number, 
        min(issuancedate::date) as date_permittd
    FROM dob_permitissuance
    WHERE jobdocnum = '01'
    AND jobtype ~* 'A1|DM|NB'
    GROUP BY jobnum
) 
SELECT 
    a.job_number,
    b.date_permittd,
    -- year_permit
    extract(year from b.date_permittd)::text as permit_year,
    -- quarter_permit
    year_quarter(b.date_permittd) as permit_qrtr
INTO STATUS_Q_devdb
FROM INIT_devdb a
LEFT JOIN STATUS_Q_create b
ON a.job_number = b.job_number