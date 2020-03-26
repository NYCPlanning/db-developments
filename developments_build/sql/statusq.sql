-- populate the status q field
-- date of the oldest issuance date for that job number in dob_permitissuance
WITH minissuancedate as (
	SELECT jobnum, min(issuancedate::date) as minissuancedate
	FROM dob_permitissuance
	WHERE jobdocnum = '01' 
	AND (jobtype = 'A1' OR jobtype = 'DM' OR jobtype = 'NB') 
	GROUP BY jobnum
)

UPDATE developments a
SET status_q = b.minissuancedate
FROM minissuancedate b
WHERE a.job_number = b.jobnum;

-- populate the year_permit field with the year of the status q date
UPDATE developments a
SET year_permit = LEFT(status_q,4);

-- set the year complete the status q year for demos
UPDATE developments a
SET year_complete = LEFT(status_q,4)
WHERE job_type = 'Demolition';
