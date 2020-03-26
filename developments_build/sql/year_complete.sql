UPDATE developments
SET year_complete = NULL
WHERE job_type = 'Demolition'
AND status = 'Withdrawn'
AND year_complete IS NOT NULL;