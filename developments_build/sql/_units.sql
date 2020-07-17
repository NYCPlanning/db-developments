
/*
ASSIGN manually-created class B and hotel unit fields from corrections file
Do not populate hotels or class B if class A is corrected
*/


/*
DESCRIPTION:
    This script assigns manually-created units fields for devdb
	1. Assign hotel_init and hotel_prop
	2. Assign otherb_init and otherb_prop
	3. Do not assign manually-created units if classa value has been edited

INPUTS: 
	CLASSA_devdb (
		job_number text, 
		classa_init numeric,
		classa_prop numeric,
		classa_net numeric
	)


OUTPUTS:
	UNITS_devdb (
		job_number text, 
		classa_init numeric,
		classa_prop numeric,
		hotel_init numeric,
		hotel_prop numeric,
		otherb_init numeric,
		otherb_prop numeric,
		classa_net numeric
	)

IN PREVIOUS VERSION: 
    units_.sql
	units_net.sql
*/

DROP TABLE IF EXISTS _UNITS_devdb;
WITH
CLASSA_init_corrected AS (
    SELECT job_number
    FROM CORR_devdb
    WHERE 'classa_init' = ANY(x_dcpedited)
),

CLASSA_prop_corrected AS (
    SELECT job_number
    FROM CORR_devdb
    WHERE 'classa_prop' = ANY(x_dcpedited)
),

UNITS_hotel_init AS (
	SELECT a.*, b.hotel_init 
		FROM CLASSA_devdb a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as hotel_init
		FROM housing_input_research
		WHERE field = 'hotel_init'
		AND job_number NOT IN
		(SELECT job_number 
		FROM CLASSA_init_corrected)) b
		ON a.job_number = b.job_number
),

UNITS_hotel_prop AS (
	SELECT a.*, b.hotel_prop 
		FROM UNITS_hotel_init a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as hotel_prop
		FROM housing_input_research
		WHERE field = 'hotel_prop'
		AND job_number NOT IN
		(SELECT job_number 
		FROM CLASSA_prop_corrected)) b
		ON a.job_number = b.job_number
),

UNITS_classb_init AS (
	SELECT a.*, b.otherb_init
		FROM UNITS_hotel_prop a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as otherb_init
		FROM housing_input_research
		WHERE field = 'otherb_init'
		AND job_number NOT IN
		(SELECT job_number 
		FROM CLASSA_init_corrected)) b
		ON a.job_number = b.job_number
),

UNITS_classb_prop AS (
	SELECT a.*, b.otherb_prop
		FROM UNITS_classb_init a
		LEFT JOIN
		(SELECT job_number, new_value::numeric as otherb_prop
		FROM housing_input_research
		WHERE field = 'otherb_prop'
		AND job_number NOT IN
		(SELECT job_number 
		FROM CLASSA_prop_corrected)) b
		ON a.job_number = b.job_number
)
SELECT 
	distinct 
	job_number,
	job_type,
	classa_init,
	classa_prop,
	hotel_init,
	hotel_prop,
	otherb_init,
	otherb_prop
INTO UNITS_devdb
FROM UNITS_classb_prop;