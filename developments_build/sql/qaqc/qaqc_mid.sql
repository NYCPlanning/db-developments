/** QAQC
	JOB_TYPE:
		dem_nb_overlap
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
DROP TABLE IF EXISTS DUP_diff_job_number;
WITH
JOBNUMBER_dup_equal_units AS (
    SELECT a.job_number, b.job_number as equal_units_match,
    	a.geo_bbl, a.address
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.geo_bbl = b.geo_bbl
    AND a.address = b.address
    AND a.classa_net = b.classa_net
    AND a.job_number < b.job_number
),

JOBNUMBER_dup_diff_units AS (
    SELECT a.job_number, b.job_number as diff_units_match,
    a.geo_bbl, a.address
    FROM MID_devdb a 
    JOIN MID_devdb b 
    ON a.job_type = b.job_type
    AND a.geo_bbl = b.geo_bbl
    AND a.address = b.address
    AND a.classa_net <> b.classa_net
    AND a.job_number < b.job_number
),


MATCHES_dup_diff_equal_units AS (
    SELECT a.job_number as job_number_a, a.equal_units_match as job_number_b, 1 as equal_units,
    a.geo_bbl, a.address
    FROM JOBNUMBER_dup_equal_units a
    UNION
    SELECT b.job_number as job_number_b, b.diff_units_match as job_number_b, 0 as equal_units,
    b.geo_bbl, b.address
    FROM JOBNUMBER_dup_diff_units b
    ORDER BY job_number_a
)

SELECT *
INTO DUP_diff_job_number
FROM MATCHES_dup_diff_equal_units;

DROP TABLE IF EXISTS MATCH_dem_nb;
WITH
JOBNUMBER_dem_nb_overlap AS (
    SELECT a.job_number as job_number_dem, 
    	b.job_number as job_number_nb,
    	a.geo_bbl
    FROM MID_devdb a
	JOIN MID_devdb b 
	ON a.geo_bbl = b.geo_bbl
	WHERE a.job_type = 'Demolition'
	AND b.job_type = 'New Building'
)

SELECT *
INTO MATCH_dem_nb
FROM JOBNUMBER_dem_nb_overlap;


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
	(CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM DUP_diff_job_number WHERE equal_units=1) THEN 1
	 	ELSE 0
	END) as dup_equal_units,
	(CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM DUP_diff_job_number WHERE equal_units=0) THEN 1
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
	END) as b_likely_occ_desc,
	(CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) THEN 1
	 	ELSE 0
	END) as units_co_prop_mismatch,
	(CASE 
	 	WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) THEN 1
	 	ELSE 0
	END) as z_incomp_tract_home,
	(CASE 
	 	WHEN a.job_number IN (SELECT job_number_dem FROM MATCH_dem_nb) THEN 1
	 	WHEN a.job_number IN (SELECT job_number_nb FROM MATCH_dem_nb) THEN 1
	 	ELSE 0
	END) as dem_nb_overlap
	
INTO MID_qaqc
FROM STATUS_qaqc a;