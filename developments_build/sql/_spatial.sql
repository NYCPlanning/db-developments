/*
DESCRIPTION:
    1. Fill spatial boundry NULLs in GEO_devdb through spatial join
    and create SPATIAL_devdb. Note that SPATIAL_devdb is the 
    consolidated table for all spatial attributes 

        _GEO_devdb -> GEO_devdb -> _SPATIAL_devdb
        _SPATIAL_devdb + GEO_devdb -> SPATIAL_devdb

INPUTS: 
    GEO_devdb
    _SPATIAL_devdb

OUTPUTS:
    SPATIAL_devdb (
        same schema as GEO_devdb
    )
*/
DROP TABLE IF EXISTS _SPATIAL_devdb;
SELECT 
    uid,
    get_cb(geom) as geo_censusblock2010,
    get_ct(geom) as geo_censustract2010,
    get_csd(geom) as geo_csd,
    get_boro(geom) as geo_boro,
    get_bbl(geom) as geo_bbl,
    get_zipcode(geom) as geo_zipcode,
    get_policeprct(geom) as geo_policeprct,
    get_firecompany(geom) as geo_firecompany,
    get_firebattalion(geom) as geo_firebattalion,
    get_firedivision(geom) as geo_firedivision,
    get_bin(geom) as geo_bin,
    get_base_bbl(geom) as base_bbl,
    get_schoolelmntry(geom) as geo_schoolelmntry,
    get_schoolmiddle(geom) as geo_schoolmiddle,
    get_schoolsubdist(geom) as geo_schoolsubdist
INTO _SPATIAL_devdb
FROM GEO_devdb;

DROP TABLE IF EXISTS SPATIAL_devdb;
WITH DRAFT_spatial as (
SELECT
    distinct
    a.uid,

    -- geo_bbl
    (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        OR a.mode = 'tpad'
        THEN b.geo_bbl
    ELSE a.geo_bbl END) as geo_bbl, 

    -- geo_bin
    (CASE WHEN (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        OR a.mode = 'tpad'
        THEN b.geo_bbl
    ELSE a.geo_bbl END) = b.base_bbl
        AND (a.geo_bin IS NULL 
            OR a.geo_bin = '' 
            OR a.geo_bin::NUMERIC%1000000=0)
            OR a.mode = 'tpad'
        AND b.base_bbl IS NOT NULL
        THEN b.geo_bin
    ELSE a.geo_bin END) as geo_bin,

    a.geo_address_numbr,
    a.geo_address_street,
    a.geo_address,

    -- geo_zipcode
    (CASE WHEN a.geo_zipcode IS NULL 
        OR a.geo_zipcode = ''
        OR a.mode = 'tpad'
        THEN b.geo_zipcode
    ELSE a.geo_zipcode END) as geo_zipcode, 

    -- geo_boro
    (CASE WHEN a.geo_boro IS NULL 
        OR a.geo_boro = '0'
        OR a.mode = 'tpad'
        THEN b.geo_boro::text
    ELSE a.geo_boro END) as geo_boro,

    -- geo_censusblock2010
    (CASE WHEN a.geo_censusblock2010 IS NULL 
		OR a.geo_censusblock2010 = '' 
		OR a.geo_censustract2010 = '000000' 
        OR a.mode = 'tpad'
        THEN b.geo_censusblock2010
    ELSE a.geo_censusblock2010 END) as geo_censusblock2010, 

    -- geo_censustract2010
   (CASE WHEN a.geo_censustract2010 IS NULL 
		OR a.geo_censustract2010 = '' 
		OR a.geo_censustract2010 = '000000'
        OR a.mode = 'tpad' 
        THEN b.geo_censustract2010
    ELSE a.geo_censustract2010 END) as geo_censustract2010, 
   
    -- geo_csd
    (CASE WHEN a.geo_csd IS NULL 
		OR a.geo_csd = '' 
        OR a.mode = 'tpad'
        THEN b.geo_csd
    ELSE a.geo_csd END) as geo_csd, 

    -- geo_policeprct
    (CASE WHEN a.geo_policeprct IS NULL 
		OR a.geo_policeprct = '' 
        OR a.mode = 'tpad'
        THEN b.geo_policeprct
    ELSE a.geo_policeprct END) as geo_policeprct, 

    -- geo_firedivision
    (CASE WHEN a.geo_firedivision IS NULL 
		OR a.geo_firedivision = '' 
        OR a.mode = 'tpad'
        THEN b.geo_firedivision
    ELSE a.geo_firedivision END) as geo_firedivision, 

    -- geo_firebattalion
    (CASE WHEN a.geo_firebattalion IS NULL 
		OR a.geo_firebattalion = '' 
        OR a.mode = 'tpad'
        THEN b.geo_firebattalion
    ELSE a.geo_firebattalion END) as geo_firebattalion, 

    -- geo_firecompany
    (CASE WHEN a.geo_firecompany IS NULL 
		OR a.geo_firecompany = '' 
        OR a.mode = 'tpad'
        THEN b.geo_firecompany
    ELSE a.geo_firecompany END) as geo_firecompany, 

    b.geo_schoolelmntry,
    b.geo_schoolmiddle,
    b.geo_schoolsubdist,
    a.geo_latitude,
    a.geo_longitude,
    a.latitude,
    a.longitude,
    a.geom,
    geomsource
FROM GEO_devdb a
LEFT JOIN _SPATIAL_devdb b
ON a.uid = b.uid
)
SELECT
    a.*,
    b.nta as geo_ntacode2010,
    b.ntaname as geo_ntaname2010,
    b.puma as geo_puma,
    b.councildst as geo_council,
    b.commntydst as geo_cd
INTO SPATIAL_devdb
FROM DRAFT_spatial a
LEFT JOIN lookup_geo b
ON a.geo_boro||a.geo_censusblock2010||a.geo_censustract2010 = b.bctcb2010