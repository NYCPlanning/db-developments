-- populate units_net to capture proposed net change in units
-- negative for demolitions, proposed for new buildings, and net change for alterations
-- (note: if an alteration is missing value for existing or proposed units, value set to null)
-- only calculated when both units_init and units_prop are available
UPDATE developments 
SET units_net =
	(CASE
		WHEN job_type = 'Demolition' AND units_init ~ '[0-9]' THEN units_init::numeric * -1
		WHEN job_type = 'New Building' AND units_prop ~ '^[0-9\.]+$' THEN units_prop::numeric
		WHEN job_type = 'Alteration' AND units_init::integer IS NOT NULL AND units_prop::integer IS NOT NULL AND units_prop ~ '^[0-9\.]+$' AND units_init ~ '[0-9]' THEN units_prop::integer - units_init::integer
		ELSE NULL 
	END)
WHERE units_init ~ '[0-9]' AND units_prop ~ '^[0-9\.]+$' AND units_init IS NOT NULL AND units_prop IS NOT NULL;