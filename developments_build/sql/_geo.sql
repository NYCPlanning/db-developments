/*
DESCRIPTION:
    1. Merging _INIT_devdb with GEO_devdb to INIT_devdb
    2. Deduplicating INIT_devdb that share the same 
        job_number, note that in the end product, 
        job_number will be the unique identifier.
    3. Corrections: remove records by bbl and job_number

INPUTS: 
    _INIT_devdb (
        * uid,
        ...
    )

    GEO_devdb (
        * uid,
        ...
    )

    housing_input_research (
        * job_number
    )

    dof_dtm (
        * bbl,
        geom
    )

    dcp_mappluto (
        * bbl,
        geom
    )

OUTPUT 
    INIT_devdb (
        _INIT_devdb.*,
        geo_bbl text,
        geo_bin text,
        geo_address_house text,
        geo_address_street text,
        geo_address text,
        geo_zipcode text,
        geo_boro text,
        geo_cd text,
        geo_council text,
        geo_ntacode2010 text,
        geo_censusblock2010 text,
        geo_censustract2010 text,
        geo_csd text,
        geo_policeprct text,
        geo_latitude double precision,
        geo_longitude double precision,
        latitude double precision,
        longitude double precision,
        geom geometry,
        x_geomsource text
    )

IN PREVIOUS VERSION: 
    geo_merge.sql
    geoaddress.sql
    geombbl.sql
    latlon.sql
    dedupe_job_number.sql
    dropmillionbin.sql
*/
DROP TABLE IF EXISTS INIT_devdb;
WITH
DRAFT as (
    SELECT
        a.*,
        b.geo_bbl,
        NULLIF(RIGHT(b.geo_bin,6),'000000') as geo_bin,
        b.geo_address_house,
        b.geo_address_street,
        concat(
            trim(b.geo_address_house),' ',
            trim(b.geo_address_street)
        )as geo_address,
        b.geo_zipcode,
        b.geo_boro, 
        b.geo_cd,
        b.geo_council,
        b.geo_ntacode2010, 
        b.geo_censusblock2010, 
        b.geo_censustract2010,
        b.geo_csd,
        b.geo_policeprct,
        b.latitude::double precision as geo_latitude,
        b.longitude::double precision as geo_longitude
	FROM _INIT_devdb a
	LEFT JOIN GEO_devdb b
	ON a.uid = b.uid::integer
),
GEOM_geosupport as (
    SELECT
        uid,
        job_number,
		bbl,
        geo_bbl,
        ST_SetSRID(ST_Point(geo_longitude,geo_latitude),4326) as geom,
        (CASE WHEN geo_longitude IS NOT NULL 
		 THEN 'Lat/Long geosupport' END) as x_geomsource
    FROM DRAFT
),
GEOM_mappluto as (
    SELECT
        a.uid,
        a.job_number,
		a.bbl,
        a.geo_bbl,
        coalesce(a.geom, ST_Centroid(b.geom)) as geom,
        (CASE 
		 	WHEN a.x_geomsource IS NOT NULL 
		 		THEN a.x_geomsource 
		 	WHEN a.geom IS NULL 
		 		AND b.geom IS NOT NULL 
		 		THEN 'BBL geosupport MapPLUTO'
		END) as x_geomsource
    FROM GEOM_geosupport a
    LEFT JOIN dcp_mappluto b
    ON a.geo_bbl = b.bbl::bigint::text
),
GEOM_mappluto_dob as (
	SELECT
        a.uid,
        a.job_number,
		a.bbl,
        a.geo_bbl,
        coalesce(a.geom, ST_Centroid(b.geom)) as geom,
        (CASE 
		 	WHEN a.x_geomsource IS NOT NULL 
		 		THEN a.x_geomsource 
		 	WHEN a.geom IS NULL 
		 		AND b.geom IS NOT NULL 
		 		THEN 'BBL DOB MapPLUTO'
		END) as x_geomsource
    FROM GEOM_mappluto a
    LEFT JOIN dcp_mappluto b
    ON a.bbl = b.bbl::bigint::text
),
DTM as (
    SELECT 
        bbl, 
        ST_Union(geom) as geom
    FROM dof_dtm
    GROUP BY bbl
),
GEOM_dtm_dob as (
	SELECT
        a.uid,
        a.job_number,
		a.bbl,
        a.geo_bbl,
        coalesce(a.geom, ST_Centroid(b.geom)) as geom,
        (CASE 
		 	WHEN a.x_geomsource IS NOT NULL 
		 		THEN a.x_geomsource 
		 	WHEN a.geom IS NULL 
		 		AND b.geom IS NOT NULL 
		 		THEN 'BBL DOB DTM'
		END) as x_geomsource
    FROM GEOM_mappluto_dob a
    LEFT JOIN DTM b
    ON a.bbl = b.bbl::bigint::text
)
SELECT
    a.*,
    ST_Y(b.geom) as latitude,
    ST_X(b.geom) as longitude,
    b.geom,
    b.x_geomsource
INTO INIT_devdb
FROM DRAFT a
LEFT JOIN GEOM_dtm_dob b
ON a.uid = b.uid;

/*
DEDUPLICATION

For any records that share an identical job_number and BBL, 
keep only the record with the most recent date_lastupdt 
value and remove the older record(s). After this step, job_number
in INIT_devdb will be the uid

*/
WITH latest_records AS (
	SELECT
        job_number, 
        geo_bbl, 
        MAX(status_date) AS date_lastupdt
	FROM INIT_devdb
	GROUP BY job_number, geo_bbl
	HAVING COUNT(*)>1
)
DELETE FROM INIT_devdb a
USING latest_records b
WHERE a.job_number = b.job_number
AND a.geo_bbl = b.geo_bbl
AND a.status_date != b.date_lastupdt;

/* 
CORRECTIONS

    job_number (removal)
    bbl (removal)

*/
INSERT INTO housing_input_research 
    (job_number, field)
SELECT 
    job_number, 'remove' as field
FROM INIT_devdb
WHERE UPPER(job_description) LIKE '%BIS%TEST%' 
    OR UPPER(job_description) LIKE '% TEST %'
AND job_number NOT IN(
    SELECT DISTINCT job_number
    FROM housing_input_research
    WHERE field = 'remove');

DELETE FROM INIT_devdb a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'remove';

DELETE FROM INIT_devdb a
USING housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'bbl'
AND a.geo_bbl = b.old_value
AND b.new_value IS NULL;

-- -- longitude latitude geom
-- UPDATE INIT_devdb a
-- SET latitude = b.new_value::double precision,
-- 	x_dcpedited = 'Edited',
-- 	x_reason = b.reason
-- FROM housing_input_research b
-- WHERE a.job_number=b.job_number
-- AND b.field = 'latitude'
-- AND ((a.job_number IN (SELECT job_number FROM dev_qc_unclipped)) 
-- 	OR ((a.latitude IS NULL OR a.latitude = '') AND b.new_value IS NOT NULL)
-- 	OR (ROUND(b.old_value::numeric,8) = ROUND(a.latitude::numeric,8)));

-- UPDATE INIT_devdb a
-- SET longitude = b.new_value::double precision,
-- 	x_dcpedited = 'Edited',
-- 	x_reason = b.reason,
-- 	x_geomsource = 'Lat/Long DCP'
-- FROM housing_input_research b
-- WHERE a.job_number=b.job_number
-- AND b.field = 'longitude'
-- AND ((a.job_number IN (SELECT job_number FROM dev_qc_unclipped)) 
-- 	OR ((a.longitude IS NULL OR a.longitude = '') AND b.new_value IS NOT NULL) 
-- 	OR (ROUND(b.old_value::numeric,8) = ROUND(a.longitude::numeric,8)));

-- UPDATE INIT_devdb
-- SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
-- WHERE x_geomsource = 'Lat/Long DCP';