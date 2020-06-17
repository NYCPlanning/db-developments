/** QAQC
    UNITS:
        units_init_null
	    units_init_null
        dup_equal_units
        dup_diff_units
    OCC:
        b_nonres_with_units
	    units_res_accessory
	    b_likely_occ_desc
    CO:
        units_co_prop_mismatch
    STATUS:
        z_incomp_tract_home
**/

DROP TABLE IF EXISTS MID_qaqc;
WITH

JOBNUMBER_all AS(
	SELECT DISTINCT job_number
	FROM MID_devdb
),

JOBNUMBER_null_init AS(
    SELECT job_number
    FROM MID_devdb
    WHERE
    job_type IN ('Demolition' , 'Alteration') 
    AND resid_flag = 'Residential' 
    AND classa_init IS NULL),

JOBNUMBER_null_prop AS(
    SELECT job_number
    FROM MID_devdb
    WHERE
    job_type IN ('New Building' , 'Alteration') 
    AND resid_flag = 'Residential' 
    AND classa_prop IS NULL),   

JOBNUMBER_dup_equal_units AS (
    SELECT a.job_number, b.job_number as dup_equal_units
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.bbl = b.bbl
    AND a.address = b.address
    AND a.classa_net = b.classa_net
    AND a.job_number <> b.job_number
),

JOBNUMBER_dup_diff_units AS (
    SELECT a.job_number, b.job_number as dup_diff_units
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.bbl = b.bbl
    AND a.address = b.address
    AND a.classa_net <> b.classa_net
    AND a.job_number <> b.job_number
),

MATCHES_dup_equal_units AS (
    SELECT a.job_number, b.dup_equal_units
    FROM JOBNUMBER_all a
    LEFT JOIN JOBNUMBER_dup_equal_units b
    ON a.job_number = b.job_number
),


MATCHES_dup_diff_equal_units AS (
    SELECT a.job_number, a.dup_equal_units, b.dup_diff_units
    FROM MATCHES_dup_equal_units a
    LEFT JOIN JOBNUMBER_dup_diff_units b
    ON a.job_number = b.job_number
),


JOBNUMBER_nonres_units AS (
	SELECT job_number 
	FROM MID_devdb
	WHERE resid_flag IS NULL
	AND (classa_prop <> 0 OR classa_init <> 0)
),

JOBNUMBER_accessory AS (
	SELECT job_number
	FROM MID_devdb
	WHERE ((address LIKE '%GAR%' 
					OR job_desc ~* 'pool|shed|gazebo|garage')
			AND (classa_init::numeric IN (1,2) 
					OR classa_prop::numeric IN (1,2)))
	OR ((occ_initial LIKE '%(U)%'
			OR occ_initial LIKE '%(K)%'
			OR occ_proposed LIKE '%(U)%'
			OR occ_proposed LIKE '%(K)%')
		AND (classa_init::numeric > 0 
			OR classa_prop::numeric > 0))
),

JOBNUMBER_b_likely AS (
    SELECT job_number
    FROM MID_devdb
    WHERE (job_type = 'Alteration' 
            AND (occ_initial LIKE '%Residential%' AND occ_proposed LIKE '%Hotel%') 
            OR (occ_initial LIKE '%Hotel%' AND occ_proposed LIKE '%Residential%'))
    OR job_desc ~* CONCAT('Hotel|Motel|Boarding|Hoste|Lodge|UG 5', '|',
                          'Group 5|Grp 5|Class B|SRO|Single room', '|',
                          'Furnished|Rooming unit|Dorm|Transient', '|',
                          'Homeless|Shelter|Group quarter|Beds', '|',
                          'Convent|Monastery|Accommodation|Harassment', '|',
                          'CNH|Settlement|Halfway|Nursing home|Assisted|')
),

JOBNUMBER_co_prop_mismatch AS (
    SELECT job_number
    FROM MID_devdb
    WHERE job_type = 'New Building' 
    AND classa_complt::numeric - classa_prop::numeric > 50
),

JOBNUMBER_incomplete_tract AS (
    SELECT job_number
    FROM MID_devdb
    WHERE tracthomes = 'Y'
    AND job_status LIKE 'Complete'
)

SELECT a.*,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_null_init) THEN 1
	 	ELSE 0
	END) as units_init_null,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_null_prop) THEN 1
	 	ELSE 0
	END) as units_prop_null,
    b.dup_equal_units,
    b.dup_diff_units,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_nonres_units) THEN 1
	 	ELSE 0
	END) as b_nonres_with_units,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_accessory) THEN 1
	 	ELSE 0
	END) as units_res_accessory,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_b_likely) THEN 1
	 	ELSE 0
	END) as b_likely_occ_desc,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) THEN 1
	 	ELSE 0
	END) as units_co_prop_mismatch,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) THEN 1
	 	ELSE 0
	END) as z_incomp_tract_home

    
INTO MID_devdb
FROM STATUS_qaqc a
JOIN MATCHES_dup_diff_equal_units b
ON a.job_number = b.job_number;