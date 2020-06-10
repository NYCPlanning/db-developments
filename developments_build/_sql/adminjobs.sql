-- remove administrative jobs 
DELETE FROM developments 
WHERE upper(job_description) LIKE '%NO WORK%'
OR ((upper(job_description) LIKE '%ADMINISTRATIVE%'
	AND job_type <> 'NB')
OR (upper(job_description) LIKE '%ADMINISTRATIVE%'
	AND upper(job_description) NOT LIKE '%ERECT%'
	AND job_type = 'NB'));