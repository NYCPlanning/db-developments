/** QAQC
	JOB_TYPE:
		dem_nb_overlap
    UNITS:
        units_init_null
	    units_init_null
        dup_equal_units -> dup_bbl_address_units
        dup_diff_units -> dup_bbl_address
    OCC:
        b_nonres_with_units
	    units_res_accessory
	    b_likely_occ_desc
    CO:
        units_co_prop_mismatch
    STATUS:
        z_incomp_tract_home
**/

DROP TABLE IF EXISTS MATCH_dem_nb;
SELECT a.job_number as job_number_dem, 
	b.job_number as job_number_nb,
	a.geo_bbl
INTO MATCH_dem_nb
FROM MID_devdb a
JOIN MID_devdb b
ON a.geo_bbl = b.geo_bbl
WHERE a.job_type = 'Demolition'
AND b.job_type = 'New Building';

DROP TABLE IF EXISTS MID_qaqc;
WITH
BBL_ADDRESS_groups AS (
	SELECT COALESCE(geo_bbl, 'NULL BBL') as geo_bbl, address
	FROM MID_devdb
	WHERE job_inactive IS NULL
	AND address IS NOT NULL
	GROUP BY COALESCE(geo_bbl, 'NULL BBL'), address 
	HAVING COUNT(*) > 1
),
BBL_ADDRESS_UNIT_groups AS (
	SELECT COALESCE(geo_bbl, 'NULL BBL') as geo_bbl, address, classa_net
	FROM MID_devdb
	WHERE job_inactive IS NULL
	AND address IS NOT NULL
	AND classa_net IS NOT NULL
	GROUP BY COALESCE(geo_bbl, 'NULL BBL'), address, classa_net
	HAVING COUNT(*) > 1
),
JOBNUMBER_duplicates AS(
SELECT 
	job_number,

	CASE WHEN geo_bbl||address||classa_net
		IN (SELECT geo_bbl||address||classa_net 
			FROM BBL_ADDRESS_UNIT_groups)
		THEN  COALESCE(geo_bbl, 'NULL BBL')||' : '||address||' : '||classa_net
		ELSE NULL
	END as dup_bbl_address_units,
	
	CASE WHEN geo_bbl||address
		IN (SELECT geo_bbl||address 
			FROM BBL_ADDRESS_groups)
		THEN COALESCE(geo_bbl, 'NULL BBL')||' : '||address
		ELSE NULL
	END as dup_bbl_address
		
FROM MID_devdb a
),
JOBNUMBER_null_init AS(
    SELECT job_number
    FROM MID_devdb
    WHERE
    job_type IN ('Demolition' , 'Alteration') 
    AND resid_flag = 'Residential' 
    AND classa_init IS NULL
),
JOBNUMBER_null_prop AS(
    SELECT job_number
    FROM MID_devdb
    WHERE
    job_type IN ('New Building' , 'Alteration') 
    AND resid_flag = 'Residential' 
    AND classa_prop IS NULL
), 
JOBNUMBER_nonres_units AS (
	SELECT job_number 
	FROM MID_devdb
	WHERE (occ_initial !~* 'residential' AND classa_init <> 0 AND classa_init IS NOT NULL)
	OR (occ_proposed !~* 'residential' AND classa_prop <> 0 AND classa_prop IS NOT NULL)
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
    WHERE occ_initial ~* 'hotel|assisted|incapacitated|restrained'
	OR occ_proposed ~* 'hotel|assisted|incapacitated|restrained'
    OR job_desc ~* CONCAT('Hotel|Motel|Boarding|Hoste|Lodge|UG 5', '|',
                          'Group 5|Grp 5|Class B|SRO|Single room', '|',
                          'Furnished|Rooming unit|Dorm|Transient', '|',
                          'Homeless|Shelter|Group quarter|Beds', '|',
                          'Convent|Monastery|Accommodation|Harassment', '|',
                          'CNH|Settlement|Halfway|Nursing home|Assisted|')
),
JOBNUMBER_co_prop_mismatch AS (
    SELECT job_number, co_latest_certtype
    FROM MID_devdb
    WHERE job_type ~* 'New Building|Alteration' 
    AND co_latest_units <> classa_prop
),
JOBNUMBER_incomplete_tract AS (
    SELECT job_number
    FROM MID_devdb
    WHERE tracthomes = 'Y'
    AND job_status LIKE 'Complete'
),
_MID_qaqc AS (
SELECT 
	a.*,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_null_init) 
		THEN 1 ELSE 0
	END) as units_init_null,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_null_prop) 
		THEN 1 ELSE 0
	END) as units_prop_null,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_nonres_units) 
		THEN 1 ELSE 0
	END) as b_nonres_with_units,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_accessory) 
		THEN 1 ELSE 0
	END) as units_res_accessory,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_b_likely) 
		THEN 1 ELSE 0
	END) as b_likely_occ_desc,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) 
		THEN (
			SELECT b.co_latest_certtype 
			FROM JOBNUMBER_co_prop_mismatch b
			where b.job_number=a.job_number
		)  ELSE NULL
	END) as units_co_prop_mismatch,
	(CASE 
		WHEN a.job_number IN (SELECT job_number FROM JOBNUMBER_co_prop_mismatch) 
		THEN 1 ELSE 0
	END) as z_incomp_tract_home,
	(CASE 
		WHEN a.job_number IN (SELECT job_number_dem FROM MATCH_dem_nb) THEN 1
		WHEN a.job_number IN (SELECT job_number_nb FROM MATCH_dem_nb) THEN 1
		ELSE 0
	END) as dem_nb_overlap
FROM STATUS_qaqc a)
SELECT 
	a.*, 
	b.dup_bbl_address, 
	b.dup_bbl_address_units
INTO MID_qaqc
FROM _MID_qaqc a
JOIN JOBNUMBER_duplicates b 
ON a.job_number = b.job_number;