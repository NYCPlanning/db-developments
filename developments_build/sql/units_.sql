DROP TABLE IF EXISTS UNITS_devdb;
WITH
UNITS_init_prop as (
	SELECT 
		jobnumber,
		job_type,
		(CASE 
			WHEN job_type='New Building' 
				then nullif(_units_init, 0) 
			WHEN job_type='Alteration' 
				AND occ_init ~* 'hotel'
				AND occ_prop ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _units_init
		END) as units_init, 
		(CASE
			WHEN job_type='Demolition' 
				then nullif(_units_prop, 0) 
			WHEN job_type='Alteration' 
				AND occ_init ~* 'hotel'
				AND occ_prop ~* 'Residential|Assisted'
				AND x_mixeduse is null
				then 0
			ELSE _units_prop
		END) as units_prop
	FROM INIT_devdb
),
UNITS_init_prop_net as (
    SELECT 
		job_number,
		units_init,
		units_prop,
		(CASE
			WHEN job_type = 'Demolition' 
				THEN units_init * -1
			WHEN job_type = 'New Building' 
				THEN units_prop
			WHEN job_type = 'Alteration' 
				AND units_init IS NOT NULL 
				AND units_prop IS NOT NULL 
				THEN units_prop - units_init
			ELSE NULL
		END) as units_net
    FROM UNITS_init_prop
),
