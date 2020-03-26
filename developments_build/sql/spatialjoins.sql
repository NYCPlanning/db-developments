-- adding on ids from spatial joins from boundary datasets
-- community district
UPDATE developments a
	SET geo_cd = b.borocd::text
	FROM dcp_cdboundaries b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_cd IS NULL 
		OR a.geo_cd = '' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- nta
UPDATE developments a
	SET geo_ntacode2010 = b.ntacode
	FROM dcp_ntaboundaries b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_ntacode2010 IS NULL 
		OR a.geo_ntacode2010 = '' 
		OR a.x_geomsource = 'Lat/Long DCP'); 
-- census block
UPDATE developments a
	SET geo_censusblock2010 = b.cb2010
	FROM dcp_censusblocks b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_censusblock2010 IS NULL 
		OR a.geo_censusblock2010 = '' 
		OR a.geo_censustract2010 = '000000' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- census tracts
UPDATE developments a
	SET geo_censustract2010 = b.ct2010
	FROM dcp_censustracts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_censustract2010 IS NULL 
		OR a.geo_censustract2010 = '' 
		OR a.geo_censustract2010 = '000000' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- school districts
UPDATE developments a
	SET geo_csd = lpad(b.schooldist::text,2,'0')
	FROM dcp_school_districts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_csd IS NULL 
		OR a.geo_csd = '' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- borough code
UPDATE developments a
	SET geo_boro = b.borocode
	FROM dcp_boroboundaries_wi b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_boro IS NULL 
		OR a.geo_boro = '0' 
		OR a.geo_boro = '' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- council districts
UPDATE developments a
	SET geo_council = lpad(b.coundist::text,2,'0')
	FROM dcp_councildistricts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL
	AND (a.geo_council IS NULL 
		OR a.geo_council = '' 
		OR a.x_geomsource = 'Lat/Long DCP');
-- bbl
UPDATE developments a
    SET geo_bbl = b.bbl
    FROM dcp_mappluto b
    WHERE ST_Within(a.geom,b.geom)
    AND a.geom IS NOT NULL
    AND (a.geo_bbl IS NULL 
		OR a.geo_bbl = '' 
		OR a.geo_bbl ~ '^0');
-- bin
UPDATE developments a
    SET geo_bin = b.bin
    FROM doitt_buildingfootprints b
    WHERE ST_Within(a.geom,b.geom)
    AND a.geom IS NOT NULL
    AND (a.geo_bin IS NULL OR a.geo_bin = '' OR a.geo_bin::NUMERIC%1000000=0)
    AND b.base_bbl IS NOT NULL
    AND a.geo_bbl = b.base_bbl;
UPDATE developments
    SET geo_bbl = (CASE WHEN geo_bbl = '' OR geo_bbl ~ '^0'
					THEN bbl ELSE geo_bbl END),
        geo_bin = (CASE WHEN (geo_bin = '' OR geo_bin ~ '^0')
						AND (geo_bbl = '' OR geo_bbl ~ '^0')
					THEN bin ELSE geo_bin END);
-- zipcode
UPDATE developments a
    SET geo_zipcode = b.zipcode
    FROM doitt_zipcodeboundaries b
    WHERE ST_Within(a.geom,b.geom)
    AND a.geom IS NOT NULL
    AND (a.geo_zipcode IS NULL OR a.geo_zipcode = '' OR a.x_geomsource = 'Lat/Long DCP');

-- transform geo_censusblock2010 and geo_censustract2010 to be the full codes
UPDATE developments a
	SET geo_censusblock2010 = RIGHT(b.bctcb2010,4)
	FROM dcp_censusblocks b
	WHERE b.cb2010 = lpad(a.geo_censusblock2010::text, 4, '0')
	AND b.ct2010 = a.geo_censustract2010
	AND b.borocode = a.geo_boro;
UPDATE developments a
	SET geo_censusblock2010 = NULL
	WHERE a.geom IS NULL;
-- census tracts
UPDATE developments a
	SET geo_censustract2010 = RIGHT(b.boroct2010,6)
	FROM dcp_censustracts b
	WHERE replace(b.ctlabel, '.', '') = replace(a.geo_censustract2010, '.', '')
	AND b.borocode = a.geo_boro;
UPDATE developments a
	SET geo_censustract2010 = NULL
	WHERE a.geom IS NULL;


