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

    -- geo_cb2010
    (CASE WHEN a.geo_cb2010 IS NULL 
		OR a.geo_cb2010 = '' 
		OR a.geo_ct2010 = '000000' 
        OR a.mode = 'tpad'
        THEN get_cb2010(geom)
    ELSE a.geo_cb2010 END) as _geo_cb2010, 

    -- geo_ct2010
   (CASE WHEN a.geo_ct2010 IS NULL 
		OR a.geo_ct2010 = '' 
		OR a.geo_ct2010 = '000000'
        OR a.mode = 'tpad' 
        THEN get_ct2010(geom)
    ELSE a.geo_ct2010 END) as _geo_ct2010, 

    -- geo_cb2010
    (CASE WHEN a.geo_cb2020 IS NULL 
		OR a.geo_cb2020 = '' 
		OR a.geo_ct2020 = '000000' 
        OR a.mode = 'tpad'
        THEN get_cb2020(geom)
    ELSE a.geo_cb2020 END) as _geo_cb2020, 

    -- geo_ct2010
   (CASE WHEN a.geo_ct2020 IS NULL 
		OR a.geo_ct2020 = '' 
		OR a.geo_ct2020 = '000000'
        OR a.mode = 'tpad' 
        THEN get_ct2020(geom)
    ELSE a.geo_ct2020 END) as _geo_ct2020, 
   
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
),
CENSUS_TRACT_BLOCK as (
    SELECT
        distinct uid,
        (CASE
            WHEN DRAFT_spatial.geo_boro = '1' THEN '36061'
            WHEN DRAFT_spatial.geo_boro = '2' THEN '36005'
            WHEN DRAFT_spatial.geo_boro = '3' THEN '36047'
            WHEN DRAFT_spatial.geo_boro = '4' THEN '36081'
            WHEN DRAFT_spatial.geo_boro = '5' THEN '36085'
        END) as fips,
        geo_boro||_geo_ct2010||_geo_cb2010 as bctcb2010,
        geo_boro||_geo_ct2020||_geo_cb2020 as bctcb2020,
        geo_boro||_geo_ct2010 as bct2010,
        geo_boro||_geo_ct2020 as bct2020
    FROM DRAFT_spatial
)
SELECT
    DRAFT_spatial.*,
    CENSUS_TRACT_BLOCK.fips||DRAFT_spatial.geo_ct2010||DRAFT_spatial.geo_cb2010 as geo_cb2010,
    CENSUS_TRACT_BLOCK.fips||DRAFT_spatial._geo_ct2010 as geo_ct2010,
    CENSUS_TRACT_BLOCK.bctcb2010,
    CENSUS_TRACT_BLOCK.bct2010,
    CENSUS_TRACT_BLOCK.fips||DRAFT_spatial.geo_ct2020||DRAFT_spatial.geo_cb2020 as geo_cb2020,
    CENSUS_TRACT_BLOCK.fips||DRAFT_spatial._geo_ct2020 as geo_ct2020,
    CENSUS_TRACT_BLOCK.bctcb2020,
    CENSUS_TRACT_BLOCK.bct2020,
    (SELECT ntacode FROM dcp_ct2010 WHERE CENSUS_TRACT_BLOCK.bct2010 = boroct2010) as geo_nta2010,
    (SELECT ntaname FROM dcp_ct2010 WHERE CENSUS_TRACT_BLOCK.bct2010 = boroct2010) as geo_ntaname2010,
    (SELECT nta2020 FROM dcp_ct2020 WHERE CENSUS_TRACT_BLOCK.bct2020 = boroct2010) as geo_nta2020,
    (SELECT ntaname FROM dcp_ct2020 WHERE CENSUS_TRACT_BLOCK.bct2020 = boroct2010) as geo_ntaname2020,
    (SELECT cdta2020 FROM dcp_ct2020 WHERE CENSUS_TRACT_BLOCK.bct2020 = boroct2010) as geo_cdta2020,
    (SELECT councildst FROM lookup_geo WHERE CENSUS_TRACT_BLOCK.bct2010 = bct2010) as geo_council,
    (SELECT commntydst FROM lookup_geo WHERE CENSUS_TRACT_BLOCK.bct2010 = bct2010) as geo_cd
INTO SPATIAL_devdb
FROM DRAFT_spatial
LEFT JOIN CENSUS_TRACT_BLOCK ON DRAFT_spatial.uid = DRAFT_spatial.uid