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
    LEFT(b.status_q,4) as year_permit,
    (CASE WHEN job_type = 'Demolition'
        THEN LEFT(b.status_q,4)
        ELSE NULL 
    END) as year_complete
INTO STATUS_Q_devdb
FROM INIT_devdb a
JOIN STATUS_Q_create b
ON a.job_number = b.job_number