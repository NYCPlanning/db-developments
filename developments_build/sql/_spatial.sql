/*
DESCRIPTION:
    1. Fill spatial boundry NULLs in GEO_devdb through spatial join
    and create SPATIAL_devdb. Note that SPATIAL_devdb is the 
    consolidated table for all spatial attributes 

        _GEO_devdb -> GEO_devdb -> SPATIAL_devdb

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
    _SPATIAL_devdb (
        same schema as GEO_devdb
    )
*/
DROP TABLE IF EXISTS _SPATIAL_devdb;
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
SELECT * 
INTO _SPATIAL_devdb
FROM ZIP_join;