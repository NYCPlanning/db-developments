/*
DESCRIPTION:
    1. Assigning missing geoms for _GEO_devdb and create GEO_devdb
    2. Apply research corrections on (longitude, latitude, geom)

INPUTS: 
    _INIT_devdb (
        * uid,
        ...
    )

    _GEO_devdb (
        * uid,
        ...
    )

    housing_input_research (
        * job_number
    )

    dcp_mappluto (
        * bbl,
        geom
    )

OUTPUT 
    GEO_devdb (
        * uid,
        job_number
        geo_bbl text,
        geo_bin text,
        geo_address_numbr text,
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
        geomsource text
    )

IN PREVIOUS VERSION: 
    geo_merge.sql
    geoaddress.sql
    geombbl.sql
    latlon.sql
    dedupe_job_number.sql
    dropmillionbin.sql
*/
DROP TABLE IF EXISTS GEO_devdb;
WITH
DRAFT as (
    SELECT
        distinct
        a.uid,
        a.job_number,
		    a.bbl,
        a.bin,
        a.date_lastupdt,
        a.job_desc,
        b.geo_bbl,
        (CASE 
            WHEN RIGHT(b.geo_bin,6) = '000000' THEN NULL
            ELSE b.geo_bin
        END) as geo_bin,
        b.geo_address_numbr,
        b.geo_address_street,
        concat(
            trim(b.geo_address_numbr),' ',
            trim(b.geo_address_street)
        )as geo_address,
        b.geo_zipcode,
        COALESCE(REPLACE(b.geo_boro,'0', LEFT(b.geo_bin, 1)), a.boro) as geo_boro, 
        b.geo_cd,
        b.geo_council,
        b.geo_ntacode2010, 
        b.geo_censusblock2010, 
        b.geo_censustract2010,
        b.geo_csd,
        b.geo_policeprct,
        b.geo_puma,
        b.geo_firedivision,
        b.geo_firebattalion,
        b.geo_firecompany,
        b.latitude::double precision as geo_latitude,
        b.longitude::double precision as geo_longitude,
        b.mode
	FROM _INIT_devdb a
	LEFT JOIN _GEO_devdb b
	ON a.uid::text = b.uid::text
),
GEOM_dob_bin_bldgfootprints as (
    SELECT distinct
        a.uid,
        a.job_number,
		a.bbl,
        a.bin,
        a.geo_bbl,
        a.geo_bin,
        a.geo_latitude,
        a.geo_longitude,
        ST_Centroid(b.wkb_geometry) as geom,
        (CASE WHEN b.wkb_geometry IS NOT NULL 
		 	THEN 'BIN DOB buildingfootprints' 
        END) as geomsource
    FROM DRAFT a
    LEFT JOIN doitt_buildingfootprints b
    ON a.bin::text = b.bin::text
),
GEOM_geo_bin_bldgfootprints as (
	SELECT distinct
        a.uid,
        a.job_number,
		a.bbl,
        a.bin,
        a.geo_bbl,
        a.geo_bin,
        a.geo_latitude,
        a.geo_longitude,
        coalesce(a.geom, ST_Centroid(b.wkb_geometry)) as geom,
        (CASE 
          WHEN a.geomsource IS NOT NULL 
            THEN a.geomsource 
          WHEN a.geom IS NULL 
            AND b.wkb_geometry IS NOT NULL 
            THEN 'BIN DCP geosupport'
		END) as geomsource
    FROM GEOM_dob_bin_bldgfootprints a
    LEFT JOIN doitt_buildingfootprints b
    ON a.geo_bin = b.bin
),
GEOM_geosupport as (
    SELECT distinct
        a.uid,
        a.job_number,
		a.bbl,
        a.bin,
        a.geo_bbl,
        a.geo_bin,
        coalesce(
            a.geom, 
            ST_SetSRID(ST_Point(a.geo_longitude,a.geo_latitude),4326)
        ) as geom,
        (CASE 
          WHEN a.geomsource IS NOT NULL 
            THEN a.geomsource 
          WHEN a.geom IS NULL 
            AND a.geo_longitude IS NOT NULL 
            THEN 'Lat/Lon geosupport'
		END) as geomsource
    FROM GEOM_dob_bin_bldgfootprints a
),
GEOM_dob_bbl_mappluto as (
	SELECT distinct
        a.uid,
        a.job_number,
		a.bbl,
        a.bin,
        a.geo_bbl,
        coalesce(a.geom, ST_Centroid(b.wkb_geometry)) as geom,
        (CASE 
          WHEN a.geomsource IS NOT NULL 
            THEN a.geomsource 
          WHEN a.geom IS NULL 
		 		AND b.wkb_geometry IS NOT NULL 
		 		THEN 'BBL DOB MapPLUTO'
		END) as geomsource
    FROM GEOM_geosupport a
    LEFT JOIN dcp_mappluto b
    ON a.bbl = b.bbl::numeric::bigint::text
), 
buildingfootprints_historical as (
    SELECT 
        bin, 
        ST_Union(wkb_geometry) as wkb_geometry
    FROM doitt_buildingfootprints_historical
    GROUP BY bin
),
GEOM_dob_bin_bldgfp_historical as (
    SELECT distinct
        a.uid,
        a.job_number,
        coalesce(a.geom, ST_Centroid(b.wkb_geometry)) as geom,
        (CASE 
		 	WHEN a.geomsource IS NOT NULL 
		 		THEN a.geomsource 
		 	WHEN a.geom IS NULL 
		 		AND b.wkb_geometry IS NOT NULL 
		 		THEN 'BIN DOB buildingfootprints (historical)'
		END) as geomsource
    FROM GEOM_dob_bbl_mappluto a
    LEFT JOIN buildingfootprints_historical b
    ON a.bin::text = b.bin::text
),
GEOM_dob_latlon as (
    SELECT distinct
        a.uid,
        a.job_number,
        coalesce(
            a.geom, 
            b.dob_geom
        ) as geom,
        (CASE 
		 	WHEN a.geomsource IS NOT NULL 
		 		THEN a.geomsource 
		 	WHEN a.geom IS NULL 
		 		AND b.dob_geom IS NOT NULL 
		 		THEN 'Lat/Lon DOB'
		END) as geomsource
    FROM GEOM_dob_bin_bldgfp_historical a
    LEFT JOIN _INIT_devdb b
    ON a.job_number = b.job_number
)
SELECT
    distinct a.*,
    ST_Y(b.geom) as latitude,
    ST_X(b.geom) as longitude,
    b.geom,
    b.geomsource
INTO GEO_devdb
FROM DRAFT a
LEFT JOIN GEOM_dob_latlon b
ON a.uid = b.uid;

/* 
CORRECTIONS

    longitude
    latitude
    geom
    
*/
WITH LONLAT_corrections as (
    SELECT 
        a.job_number,
        coalesce(a.reason, b.reason) as reason,
        ST_SetSRID(ST_MakePoint(a.old_lon, b.old_lat), 4326) as old_geom,
        ST_SetSRID(ST_MakePoint(a.new_lon, b.new_lat), 4326) as new_geom
    FROM (
        SELECT 
            job_number,
            reason,
            (CASE
            	WHEN old_value ~ '^[-+]?[0-9]*\.?[0-9]+$' 
            	THEN old_value::double precision
	            ELSE NULL
	        END) as old_lon, 
            new_value::double precision as new_lon
        FROM housing_input_research
        WHERE field = 'longitude'
    ) a LEFT JOIN (
        SELECT 
            job_number, 
            reason,
            (CASE
            	WHEN old_value ~ '^[-+]?[0-9]*\.?[0-9]+$' 
            	THEN old_value::double precision
	            ELSE NULL
	        END) as old_lat, 
            new_value::double precision as new_lat
        FROM housing_input_research
        WHERE field = 'latitude'
    ) b ON a.job_number = b.job_number
),
GEOM_corrections as (
    SELECT
        a.job_number,
        a.old_geom,
        a.new_geom,
        a.reason,
        st_distance(a.new_geom, b.geom) as distance,
        get_bbl(b.geom) as bbl,
        in_water(b.geom) in_water
    FROM LONLAT_corrections a
    LEFT JOIN GEO_devdb b
    ON a.job_number = b.job_number
)
UPDATE GEO_devdb a
SET latitude = ST_Y(b.new_geom),
    longitude = ST_X(b.new_geom),
    geom = b.new_geom,
    geomsource = 'Lat/Lon DCP'
FROM GEOM_corrections b
WHERE a.job_number=b.job_number
AND (COALESCE(b.distance, 0) < 10 AND (b.bbl IS NULL OR b.in_water));

WITH CORR_target as (
    SELECT a.job_number, 
		COALESCE(b.reason, 'NA') as reason,
		b.edited_date
	FROM _INIT_devdb a, housing_input_research b
	WHERE a.job_number=b.job_number
    AND a.job_number in (
        SELECT distinct job_number
        FROM GEO_devdb 
        WHERE geomsource = 'Lat/Lon DCP')
)
UPDATE CORR_devdb a
SET dcpeditfields = array_cat(dcpeditfields, ARRAY['longitude', 'latitude'])
FROM CORR_target b
WHERE a.job_number=b.job_number;