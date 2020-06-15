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
SELECT 
    uid,
    get_cd(geom) as geo_cd,
    get_nta(geom) as geo_ntacode2010,
    get_cb(geom) as geo_censusblock2010,
    get_ct(geom) as geo_censustract2010,
    get_csd(geom) as geo_csd,
    get_boro(geom) as geo_boro,
    get_council(geom) as geo_council,
    get_bbl(geom) as geo_bbl,
    get_zipcode(geom) as geo_zipcode,
    get_bin(geom) as geo_bin,
    get_base_bbl(geom) as base_bbl
INTO _SPATIAL_devdb
FROM GEO_devdb;