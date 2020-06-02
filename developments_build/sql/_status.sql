WITH
STATUS_translate as (
    SELECT 
        a.job_number
        (CASE 
            WHEN a.job_type = 'Demolition' 
                AND b.dcpstatus IN ('Complete','Permit issued') 
                THEN 'Complete (demolition)'
            WHEN a.x_withdrawal IN ('W', 'C')
                THEN 'Withdrawn'
            WHEN status_p is IS NOT NULL
                THEN 'In progress'
            WHEN status_q IS NOT NULL
                THEN 'Permit issued'
            ELSE b.dcpstatus 
        END) as status
    FROM INIT_devdb a
    LEFT JOIN housing_input_lookup_status b
    ON a._status = b.dobstatus
)