-- populate the status field using the housing_input_lookup_status lookup table
UPDATE developments a
SET status = b.dcpstatus
FROM housing_input_lookup_status b
WHERE a.status=b.dobstatus;

-- update status to 'Complete (demolition)' where dob_type ='DM' AND dcp_status = 'Complete' or 'Permit issued'
UPDATE developments a
SET status =
	(CASE
		WHEN job_type = 'Demolition' AND status IN ('Complete','Permit issued') THEN 'Complete (demolition)'
		ELSE status
	END);

-- set the status to withdrawn based on the x_withdrawal attribute value
UPDATE developments
SET status = 'Withdrawn'
WHERE x_withdrawal = 'W' OR x_withdrawal = 'C';

ALTER TABLE developments
DROP COLUMN x_withdrawal;

-- set the status to In Progress if there is a date in status P
UPDATE developments
SET status = 'In progress'
WHERE status_p IS NOT NULL
	AND status NOT LIKE '%Complete%'
	AND status NOT LIKE '%Withdrawn%';

-- set the status to Permit Issued if there is a date in status Q
UPDATE developments
SET status = 'Permit issued'
WHERE status_q IS NOT NULL
	AND status NOT LIKE '%Complete%'
	AND status NOT LIKE '%Withdrawn%';

-- set the status to Complete where a TCO or FCO has been issued
UPDATE developments a
SET status = 'Complete'
WHERE co_earliest_effectivedate IS NOT NULL
AND status NOT LIKE '%Withdrawn%';

-- set the status to Partial complete for new buildings with a TCO and the co_latest_units is significantly less than units_net
-- split out into two queries 1) where units_net >= 20 and 2) where units_net >=5 and < 20
UPDATE developments a
SET status = 'Partial complete'
WHERE status = 'Complete'
AND job_type = 'New Building'
AND co_latest_certtype = 'T- TCO'
AND ((co_latest_units::double precision/units_net::double precision) < 0.8 
	AND units_net::double precision >= 20);

UPDATE developments a
SET status = 'Partial complete'
WHERE status = 'Complete'
AND job_type = 'New Building'
AND co_latest_certtype = 'T- TCO'
AND ((units_net::double precision - co_latest_units:: double precision) >=5 AND units_net::double precision BETWEEN 5 AND 19);
