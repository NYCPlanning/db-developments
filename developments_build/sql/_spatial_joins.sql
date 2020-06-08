/*
DESCRIPTION:
    1. Fill spatial boundry NULLs in GEO_devdb through spatial join
    and create SPATIAL_devdb. Note that SPATIAL_devdb is the 
    consolidated table for all spatial attributes 

        _GEO_devdb -> GEO_devdb -> SPATIAL_devdb

    2. Merge SPATIAL_devdb with _INIT_devdb and create INIT_devdb.

        SPATIAL_devdb + _INIT_devdb -> INIT_devdb

    3. remove records using job_number and bbl 
    in housing_input_research 

INPUTS: 
    GEO_devdb
    dcp_cdboundaries
    dcp_ntaboundaries
    dcp_censusblocks
    dcp_censustracts
    dcp_school_districts
    dcp_boroboundaries_wi
    dcp_councildistricts
    dcp_mappluto
    doitt_buildingfootprints
    doitt_zipcodeboundaries

OUTPUTS:
    SPATIAL_devdb (
        same schema as GEO_devdb
    )
    
    INIT_devdb (
        uid integer,
        job_number character varying,
        job_type character varying,
        job_description character varying,
        _occ_init text,
        _occ_prop text,
        stories_init numeric,
        stories_prop character varying,
        zoningsft_init numeric,
        zoningsft_prop numeric,
        _units_init numeric,
        _units_prop numeric,
        x_mixeduse text,
        _status character varying,
        status_date date,
        status_a character varying,
        status_d character varying,
        status_p character varying,
        status_r character varying,
        status_x character varying,
        zoningdist1 character varying,
        zoningdist2 character varying,
        zoningdist3 character varying,
        specialdist1 character varying,
        specialdist2 character varying,
        landmark character varying,
        cityowned character varying,
        owner_type character varying,
        owner_nonprof character varying,
        owner_firstnm character varying,
        owner_lastnm character varying,
        owner_biznm character varying,
        owner_address character varying,
        owner_zipcode character varying,
        owner_phone character varying,
        height_init character varying,
        height_prop character varying,
        constructnsf character varying,
        enlrg_horiz character varying,
        enlrg_vert character varying,
        enlargementsf character varying,
        costestimate character varying,
        loftboardcert character varying,
        edesignation character varying,
        curbcut character varying,
        tracthomes character varying,
        address_house text,
        address_street text,
        address text,
        bin character varying,
        bbl text,
        boro text,
        x_withdrawal character varying,
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
        x_geomsource text,
        x_dcpedited text,
        x_reason text
    )
*/
DROP TABLE IF EXISTS SPATIAL_devdb;
WITH
CD_join as (
    SELECT 
        a.uid,
        b.borocd as geo_cd,
        a.geom
    FROM GEO_devdb a
    LEFT JOIN dcp_cdboundaries b
    ON ST_Within(a.geom,b.geom)
),
NTA_join as (
    SELECT 
        a.*,
        b.ntacode as geo_ntacode2010
    FROM CD_join a
    LEFT JOIN dcp_ntaboundaries b
    ON ST_Within(a.geom,b.geom)
),
CB_join as (
    SELECT 
        a.*,
        b.cb2010 as geo_censusblock2010
    FROM NTA_join a
    LEFT JOIN dcp_censusblocks b
    ON ST_Within(a.geom,b.geom)
),
CT_join as (
    SELECT 
        a.*,
        b.ct2010 as geo_censustract2010
    FROM CB_join a
    LEFT JOIN dcp_censustracts b
    ON ST_Within(a.geom,b.geom)
),
CSD_join as (
    SELECT 
        a.*,
        lpad(b.schooldist::text,2,'0') as geo_csd
    FROM CT_join a
    LEFT JOIN dcp_school_districts b
    ON ST_Within(a.geom,b.geom)
),
BORO_join as (
    SELECT 
        a.*,
        b.borocode as geo_boro
    FROM CSD_join a
    LEFT JOIN dcp_boroboundaries_wi b
    ON ST_Within(a.geom,b.geom)
),
COUNCIL_join as (
    SELECT 
        a.*,
        lpad(b.coundist::text,2,'0') as geo_council
    FROM BORO_join a
    LEFT JOIN dcp_councildistricts b
    ON ST_Within(a.geom,b.geom)
),
BBL_join as (
    SELECT 
        a.*,
        b.bbl::bigint::text as geo_bbl
    FROM COUNCIL_join a
    LEFT JOIN dcp_mappluto b
    ON ST_Within(a.geom,b.geom)
),
BIN_join as (
    SELECT 
        a.*,
        b.bin as geo_bin,
        b.base_bbl as base_bbl
    FROM BBL_join a
    LEFT JOIN doitt_buildingfootprints b
    ON ST_Within(a.geom,b.geom)
),
ZIP_join as (
    SELECT 
        a.*,
        b.zipcode as geo_zipcode
    FROM BIN_join a
    LEFT JOIN doitt_zipcodeboundaries b
    ON ST_Within(a.geom,b.geom)
)
SELECT
    a.uid,

    -- geo_bbl
    (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        THEN b.geo_bbl
    ELSE a.geo_bbl END) as geo_bbl, 

    -- geo_bin
    (CASE WHEN (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        THEN b.geo_bbl
    ELSE a.geo_bbl END) = b.base_bbl
        AND (a.geo_bin IS NULL 
            OR a.geo_bin = '' 
            OR a.geo_bin::NUMERIC%1000000=0)
        AND b.base_bbl IS NOT NULL
        THEN b.geo_bin
    ELSE a.geo_bin END) as geo_bin,

    a.geo_address_house,
    a.geo_address_street,
    a.geo_address,

    -- geo_zipcode
    (CASE WHEN a.geo_zipcode IS NULL 
        OR a.geo_zipcode = ''
        THEN b.geo_zipcode
    ELSE a.geo_zipcode END) as geo_zipcode, 

    -- geo_boro
    (CASE WHEN a.geo_boro IS NULL 
        OR a.geo_boro = '0'
        THEN b.geo_boro::text
    ELSE a.geo_boro END) as geo_boro,

    -- geo_cd
    (CASE WHEN a.geo_cd IS NULL 
		OR a.geo_cd = ''
        THEN b.geo_cd::text
    ELSE a.geo_cd END) as geo_cd,

    -- geo_council
    (CASE WHEN a.geo_council IS NULL 
		OR a.geo_council = ''
        THEN b.geo_council 
    ELSE a.geo_council END) as geo_council,

    -- geo_ntacode2010
    (CASE WHEN a.geo_ntacode2010 IS NULL 
		OR a.geo_ntacode2010 = ''
        THEN b.geo_ntacode2010 
    ELSE a.geo_ntacode2010 END) as geo_ntacode2010,

    -- geo_censusblock2010
    (CASE WHEN a.geo_censusblock2010 IS NULL 
		OR a.geo_censusblock2010 = '' 
		OR a.geo_censustract2010 = '000000' 
        THEN b.geo_censusblock2010
    ELSE a.geo_censusblock2010 END) as geo_censusblock2010, 

    -- geo_censustract2010
   (CASE WHEN a.geo_censustract2010 IS NULL 
		OR a.geo_censustract2010 = '' 
		OR a.geo_censustract2010 = '000000' 
        THEN b.geo_censustract2010
    ELSE a.geo_censustract2010 END) as geo_censustract2010, 
   
    -- geo_csd
    (CASE WHEN a.geo_csd IS NULL 
		OR a.geo_csd = '' 
        THEN b.geo_csd
    ELSE a.geo_csd END) as geo_csd, 

    a.geo_policeprct,
    a.geo_latitude,
    a.geo_longitude,
    a.latitude,
    a.longitude,
    a.geom,
    x_geomsource,
    x_dcpedited,
    x_reason
INTO SPATIAL_devdb
FROM GEO_devdb a
LEFT JOIN ZIP_join b
ON a.uid = b.uid;

/*
Merging spatial attribute table to the Main attribute table
*/
DROP TABLE IF EXISTS INIT_devdb;
SELECT
    b.*,
    a.geo_bbl,
    a.geo_bin,
    a.geo_address_house,
    a.geo_address_street,
    a.geo_address,
    a.geo_zipcode,
    a.geo_boro,
    a.geo_cd,
    a.geo_council,
    a.geo_ntacode2010,
    a.geo_censusblock2010,
    a.geo_censustract2010,
    a.geo_csd,
    a.geo_policeprct,
    a.geo_latitude,
    a.geo_longitude,
    a.latitude,
    a.longitude,
    a.geom,
    a.x_geomsource,
    a.x_dcpedited,
	a.x_reason
INTO INIT_devdb
FROM SPATIAL_devdb a
LEFT JOIN _INIT_devdb b
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
