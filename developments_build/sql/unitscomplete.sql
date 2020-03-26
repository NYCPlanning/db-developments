-- simplified computation of units_complete and units_incomplete
UPDATE developments
SET units_complete =
	(CASE
		WHEN status LIKE 'Complete%' THEN units_net
		WHEN status = 'Partial complete' THEN co_latest_units
		ELSE NULL
	END),
	units_incomplete =
		(CASE
			WHEN status LIKE 'Complete%' THEN NULL
			WHEN status = 'Partial complete' THEN (units_net::numeric - co_latest_units::numeric)::text
			ELSE units_net
		END);
		
-- add on DCP attributes
UPDATE developments a
SET units_complete = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_complete'
AND (a.units_complete::numeric=b.old_value::numeric OR (a.units_complete IS NULL AND b.old_value IS NULL));

UPDATE developments a
SET units_incomplete = TRIM(b.new_value),
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'units_incomplete'
AND (a.units_incomplete::numeric=b.old_value::numeric OR (a.units_incomplete IS NULL AND b.old_value IS NULL));


-- Retired complex logic
-- Calculation is not performed if units_net or u_prop were NULL
-- UPDATE developments
-- SET units_complete =
-- 		(CASE
-- 			WHEN status = 'Complete (demolition)' AND units_net IS NOT NULL THEN units_net
-- 			WHEN status = 'Withdrawn' THEN NULL
-- 			WHEN co_latest_units IS NULL AND units_net IS NOT NULL THEN '0'
-- 			WHEN status = 'Complete' AND units_net IS NOT NULL AND job_number IN (SELECT DISTINCT job_number FROM housing_input_dcpattributes WHERE units_prop_res IS NOT NULL) THEN units_net
-- 			WHEN job_type = 'Alteration' AND status = 'Complete' AND units_net IS NOT NULL THEN units_net
-- 			WHEN job_type = 'Alteration' AND co_latest_units IS NOT NULL AND units_net IS NOT NULL THEN (co_latest_units::numeric - units_init::numeric)::text
-- 			WHEN job_type = 'New Building' AND co_latest_units IS NOT NULL AND units_net IS NOT NULL THEN co_latest_units
-- 			ELSE units_complete
-- 		END),
-- 	units_incomplete =
-- 		(CASE 
-- 			WHEN status <> 'Complete' AND units_net IS NOT NULL AND job_number IN (SELECT DISTINCT job_number FROM housing_input_dcpattributes WHERE units_prop_res IS NOT NULL) THEN units_net
-- 			WHEN units_net IS NOT NULL AND status = 'Complete' THEN '0'
-- 			WHEN units_net IS NOT NULL AND status <> 'Complete' THEN (units_net::numeric - units_complete::numeric)::text
-- 			WHEN job_type = 'Alteration' AND status <> 'Complete' AND units_net IS NOT NULL THEN units_net
-- 			WHEN units_net IS NULL AND units_prop IS NOT NULL AND co_latest_units IS NOT NULL THEN (units_prop::numeric - co_latest_units::numeric)::text
-- 			ELSE units_net
-- 		END);

