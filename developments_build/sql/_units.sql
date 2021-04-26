
/*
DESCRIPTION:
    This script assigns units fields for devdb
	1. Assign _classa_init and classa_prop
	2. Apply corrections to _classa_init and classa_prop
	3. Assign _classa_net
INPUTS: 
	INIT_devdb (
		job_number text,
		job_type text,
		_classa_init numeric,
		_classa_prop numeric
	)
	OCC_devdb (
		job_number text,
		occ_initial text,
		occ_proposed text
	)
OUTPUTS:
	UNITS_devdb (
		job_number text, 
		_classa_init numeric,
		_classa_prop numeric,
		_hotel_init numeric,
		_hotel_prop numeric,
		_otherb_init numeric,
		_otherb_prop numeric,
		_classa_net numeric
	)
IN PREVIOUS VERSION: 
    units_.sql
	units_net.sql
*/

DROP TABLE IF EXISTS _UNITS_devdb;
SELECT DISTINCT
	a.job_number,
	a.job_type,
	b.occ_proposed,
	b.occ_initial,
	a._classa_init,
	a._classa_prop,
	(CASE
		WHEN a.job_type = 'New Building' THEN 0
		ELSE NULL
	END) as _hotel_init,
	(CASE
		WHEN a.job_type = 'Demolition' THEN 0
		ELSE NULL
	END) as _hotel_prop,
	(CASE
		WHEN a.job_type = 'New Building' THEN 0
		ELSE NULL
	END) as _otherb_init,
	(CASE
		WHEN a.job_type = 'Demolition' THEN 0
		ELSE NULL
	END) as _otherb_prop
INTO _UNITS_devdb
FROM INIT_devdb a
LEFT JOIN OCC_devdb b
ON a.job_number = b.job_number;


/*
CORRECTIONS
Note that hotel/otherb corrections match old_value with
the associated classa field. As a result, these corrections
get applied prior to the classa corrections.
*/
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'hotel_init', 'classa_init');
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'hotel_prop', 'classa_prop');
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'otherb_init', 'classa_init');
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'otherb_prop', 'classa_prop');
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'classa_init', 'classa_init');
CALL apply_correction('_UNITS_devdb', 'housing_input_research', 'classa_prop', 'classa_prop');

/*
ASSIGN classa_net
*/
DROP TABLE IF EXISTS UNITS_devdb;
SELECT
	*,
	(CASE
		WHEN job_type = 'Demolition' 
			THEN _classa_init * -1
		WHEN job_type = 'New Building' 
			THEN _classa_prop
		WHEN job_type = 'Alteration' 
			AND _classa_init IS NOT NULL 
			AND _classa_prop IS NOT NULL 
			THEN _classa_prop - _classa_init
		ELSE NULL
	END) as _classa_net
INTO UNITS_devdb
FROM _UNITS_devdb;