-- setting the mixeduse flag to TRUE based on keywords in the job description
UPDATE developments
SET x_mixeduse = 'Mixed Use'
WHERE upper(job_description) LIKE '%MIX%'
	OR (upper(job_description) LIKE '%RESID%' AND upper(job_description) LIKE '%COMM%')
  	OR (upper(job_description) LIKE '%RESID%' AND upper(job_description) LIKE '%HOTEL%')
  	OR (upper(job_description) LIKE '%RESID%' AND upper(job_description) LIKE '%RETAIL%');