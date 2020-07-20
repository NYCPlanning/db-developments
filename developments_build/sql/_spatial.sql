/*
DESCRIPTION:
    1. Fill spatial boundry NULLs in GEO_devdb through spatial join
    and create SPATIAL_devdb. Note that SPATIAL_devdb is the 
    consolidated table for all spatial attributes 

        _GEO_devdb -> GEO_devdb 
        GEO_devdb --Spatial Joins--> SPATIAL_devdb

INPUTS: 
    GEO_devdb

OUTPUTS:
    SPATIAL_devdb (
        same schema as GEO_devdb
    )
*/
DROP TABLE IF EXISTS SPATIAL_devdb;
WITH DRAFT_spatial as (
SELECT
    distinct
    a.uid,

    -- geo_bbl
    (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        OR a.mode = 'tpad'
        THEN get_bbl(geom)
    ELSE a.geo_bbl END) as geo_bbl, 

    -- geo_bin
    (CASE WHEN (CASE WHEN a.geo_bbl IS NULL
        OR a.geo_bbl ~ '^0' OR a.geo_bbl = ''
        OR a.mode = 'tpad'
        THEN get_bbl(geom)
    ELSE a.geo_bbl END) = get_base_bbl(geom)
        AND (a.geo_bin IS NULL 
            OR a.geo_bin = '' 
            OR a.geo_bin::NUMERIC%1000000=0)
            OR a.mode = 'tpad'
        AND get_base_bbl(geom) IS NOT NULL
        THEN get_bin(geom)
    ELSE a.geo_bin END) as geo_bin,

    a.geo_address_numbr,
    a.geo_address_street,
    a.geo_address,

    -- geo_zipcode
    (CASE WHEN a.geo_zipcode IS NULL 
        OR a.geo_zipcode = ''
        OR a.mode = 'tpad'
        THEN get_zipcode(geom)
    ELSE a.geo_zipcode END) as geo_zipcode, 

    -- geo_boro
    (CASE WHEN a.geo_boro IS NULL 
        OR a.geo_boro = '0'
        OR a.mode = 'tpad'
        THEN get_boro(geom)::text
    ELSE a.geo_boro END) as geo_boro,

    -- geo_censusblock2010
    (CASE WHEN a.geo_censusblock2010 IS NULL 
		OR a.geo_censusblock2010 = '' 
		OR a.geo_censustract2010 = '000000' 
        OR a.mode = 'tpad'
        THEN get_cb(geom)
    ELSE a.geo_censusblock2010 END) as _geo_censusblock2010, 

    -- geo_censustract2010
   (CASE WHEN a.geo_censustract2010 IS NULL 
		OR a.geo_censustract2010 = '' 
		OR a.geo_censustract2010 = '000000'
        OR a.mode = 'tpad' 
        THEN get_ct(geom)
    ELSE a.geo_censustract2010 END) as _geo_censustract2010, 
   
    -- geo_csd
    (CASE WHEN a.geo_csd IS NULL 
		OR a.geo_csd = '' 
        OR a.mode = 'tpad'
        THEN get_csd(geom)
    ELSE a.geo_csd END) as geo_csd, 

    -- geo_policeprct
    (CASE WHEN a.geo_policeprct IS NULL 
		OR a.geo_policeprct = '' 
        OR a.mode = 'tpad'
        THEN get_policeprct(geom)
    ELSE a.geo_policeprct END) as geo_policeprct, 

    -- geo_firedivision
    (CASE WHEN a.geo_firedivision IS NULL 
		OR a.geo_firedivision = '' 
        OR a.mode = 'tpad'
        THEN get_firedivision(geom)
    ELSE a.geo_firedivision END) as geo_firedivision, 

    -- geo_firebattalion
    (CASE WHEN a.geo_firebattalion IS NULL 
		OR a.geo_firebattalion = '' 
        OR a.mode = 'tpad'
        THEN get_firebattalion(geom)
    ELSE a.geo_firebattalion END) as geo_firebattalion, 

    -- geo_firecompany
    (CASE WHEN a.geo_firecompany IS NULL 
		OR a.geo_firecompany = '' 
        OR a.mode = 'tpad'
        THEN get_firecompany(geom)
    ELSE a.geo_firecompany END) as geo_firecompany, 

    get_schoolelmntry(geom) as geo_schoolelmntry,
    get_schoolmiddle(geom) as geo_schoolmiddle,
    get_schoolsubdist(geom) as geo_schoolsubdist,
    a.geo_latitude,
    a.geo_longitude,
    a.latitude,
    a.longitude,
    a.geom,
    geomsource
FROM GEO_devdb a
)
SELECT
    a.*,
    b.fips_boro||a._geo_censustract2010||a._geo_censustract2010 as geo_censusblock2010,
    b.bctcb2010,
    b.fips_boro||a._geo_censustract2010 as geo_censustract2010,
    b.bct2010,
    b.nta as geo_ntacode2010,
    b.ntaname as geo_ntaname2010,
    b.puma as geo_puma,
    b.councildst as geo_council,
    b.commntydst as geo_cd
INTO SPATIAL_devdb
FROM DRAFT_spatial a
LEFT JOIN lookup_geo b
ON a.geo_boro||a._geo_censustract2010||a._geo_censusblock2010 = b.bctcb2010;