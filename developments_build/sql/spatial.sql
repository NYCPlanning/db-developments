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
DROP TABLE IF EXISTS SPATIAL_devdb;
SELECT
    distinct
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
    x_geomsource
INTO SPATIAL_devdb
FROM GEO_devdb a
LEFT JOIN _SPATIAL_devdb b
ON a.uid = b.uid;