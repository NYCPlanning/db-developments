-- Tag projects that have been inactive for at least 2 years
UPDATE developments
	SET x_inactive = TRUE
	WHERE status = 'In progress (last plan disapproved)'
	AND (CURRENT_DATE - status_date::date)/365 >= 2;

-- Tag projects that have been inactive for at least 3 years
UPDATE developments
	SET x_inactive = TRUE
	WHERE status = 'Filed'
	AND (CURRENT_DATE - status_date::date)/365 >= 3;

UPDATE developments
	SET x_inactive = TRUE
	WHERE status = 'In progress'
	AND (CURRENT_DATE - status_date::date)/365 >= 3;

-- Tag projects that are withdrawn
UPDATE developments
	SET x_inactive = TRUE
	WHERE status = 'Withdrawn';

-- Tag projects that are potential duplicates 
-- and the status date is older than an associated complete record
WITH completejobs AS (
	SELECT address, job_type, status_date, status
	FROM developments
	WHERE units_net::numeric > 0
	AND status LIKE 'Complete%')
UPDATE developments a 
SET x_inactive = TRUE
FROM completejobs b
WHERE a.address = b.address
	AND a.job_type = b.job_type
	AND a.status NOT LIKE 'Complete%'
	AND a.status_date::date < b.status_date::date
	AND a.status <> 'Withdrawn'
  	AND a.occ_prop <> 'Garage/Miscellaneous';
  	
-- set NULL records to false
UPDATE developments
	SET x_inactive = 'Inactive'
	WHERE x_inactive IS NOT NULL;