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
        units_co_prop_mismatch TODO
    STATUS:
        z_incomp_tract_home TODO
**/

DROP TABLE IF EXISTS MID_qaqc;
WITH
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
    SELECT a.job_number
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.bbl = b.bbl
    AND a.address = b.address
    AND a.classa_net = b.classa_net
    AND a.job_number <> b.job_number
),

JOBNUMBER_dup_diff_units AS (
    SELECT a.job_number
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.bbl = b.bbl
    AND a.address = b.address
    AND a.classa_net <> b.classa_net
    AND a.job_number <> b.job_number
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
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_dup_equal_units) THEN 1
	 	ELSE 0
	END) as dup_equal_units,
    (CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_dup_diff_units) THEN 1
	 	ELSE 0
	END) as dup_diff_units,
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
	END) as b_likely_occ_desc
    
INTO MID_qaqc
FROM UNITS_qaqc a;