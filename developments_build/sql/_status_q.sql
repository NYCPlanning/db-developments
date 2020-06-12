/*
DESCRIPTION:
    This script is created to assign/recode the field "status_q" 

INPUTS: 
    INIT_devdb (
        job_number,
        job_type,
        _status,
        x_withdrawal,
        status_p,
        status_q
    )

    dob_permitissuance (
        jobnum,
        issuancedate
    )

OUTPUTS:
    STATUS_Q_devdb (
        job_number text,
        status_q date,
        year_permit text,
        quarter_permit text,
        _year_complete text,
        _quarter_complete text
    )

*/
DROP TABLE IF EXISTS STATUS_Q_devdb;
WITH 
STATUS_Q_create as (
    SELECT 
        jobnum as job_number, 
        min(issuancedate::date) as status_q
    FROM dob_permitissuance
    WHERE jobdocnum = '01'
    AND jobtype ~* 'A1|DM|NB'
    GROUP BY jobnum
) 
SELECT 
    a.job_number,
    b.status_q,
    -- year_permit
    extract(year from b.status_q)::text as year_permit,
    -- quarter_permit
    extract(year from b.status_q)::text||'Q'
        ||EXTRACT(QUARTER FROM b.status_q)::text as quarter_permit,
    -- year_complete
    (CASE WHEN job_type = 'Demolition'
        THEN extract(year from b.status_q)::text
        ELSE NULL
    END) as _year_complete,
    -- quarter_complete
    (CASE WHEN job_type = 'Demolition'
        THEN extract(year from b.status_q)::text||'Q'
            ||EXTRACT(QUARTER FROM b.status_q)::text
        ELSE NULL
    END) as _quarter_complete
INTO STATUS_Q_devdb
FROM INIT_devdb a
LEFT JOIN STATUS_Q_create b
ON a.job_number = b.job_number