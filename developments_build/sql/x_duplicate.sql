-- Identify potential duplicate records
-- generate unique id for potential duplicates
UPDATE developments
	SET
		x_dup_id = job_type||bbl||bin||replace(address, ' ', '')
	WHERE
		status <> 'Withdrawn'
		AND status <> 'Disapproved'
		AND status <> 'Suspended'
		AND x_inactive <> 'true'
		AND 
			((units_init <> '0' AND units_prop <> '0')
				OR (units_init <> '0' AND units_prop IS NOT NULL)
				OR (units_init IS NOT NULL AND units_prop <> '0')
				OR (units_init IS NOT NULL AND units_prop IS NOT NULL)
			);

ALTER TABLE developments
ADD COLUMN x_dup_maxstatusdate text,
ADD COLUMN x_dup_maxcofodate text;

-- calculate the max status date for each unique dup id
UPDATE developments a
	SET
		x_dup_maxstatusdate = maxdate
	FROM (SELECT 
       	x_dup_id,
       	MAX(status_date) AS maxdate
       FROM developments
       WHERE x_dup_id IS NOT NULL
       GROUP BY x_dup_id) AS b
	WHERE a.x_dup_id = b.x_dup_id;
-- calculate the max cofo date for each unique dup id
UPDATE developments a
	SET
		x_dup_maxcofodate = maxdate
	FROM (SELECT
       	x_dup_id,
       	MAX(co_latest_effectivedate) AS maxdate
       FROM developments
       WHERE x_dup_id IS NOT NULL
       GROUP BY x_dup_id) AS b
	WHERE a.x_dup_id = b.x_dup_id;
-- flag possible duplicates based on records having a max status date > the status date
UPDATE developments
	SET
		x_dup_flag = 'Possible duplicate'
	WHERE
		x_dup_id IS NOT NULL
		AND x_dup_maxstatusdate > status_date
		AND x_dup_maxcofodate IS NULL
		AND co_latest_effectivedate IS NULL
		AND status <> 'Complete';
-- flag possible duplicates based on records having a max c of o date > the status date
UPDATE developments
	SET
		x_dup_flag = 'Possible duplicate'
	WHERE
		x_dup_id IS NOT NULL
		AND x_dup_maxcofodate > status_date
		AND x_dup_maxcofodate IS NOT NULL
		AND co_latest_effectivedate IS NULL
		AND status <> 'Complete';

ALTER TABLE developments
DROP COLUMN x_dup_maxstatusdate,
DROP COLUMN x_dup_maxcofodate;
