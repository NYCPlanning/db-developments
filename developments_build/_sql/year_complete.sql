UPDATE developments
SET year_complete = NULL
WHERE (job_type = 'Demolition'
OR status = 'Withdrawn')
AND year_complete IS NOT NULL;