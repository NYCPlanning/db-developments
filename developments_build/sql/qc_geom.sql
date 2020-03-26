DROP TABLE IF EXISTS qc_geom;
SELECT job_number, bbl AS geo_bbl, bin AS geo_bin, zipcode AS geo_zipcode, bcode AS geo_boro, cd AS geo_cd,
council AS geo_council, nta AS geo_ntacode2010, cblock AS geo_censusblock2010, ct AS geo_censustract2010,
csd AS geo_csd, lat AS latitude, lon AS longitude
INTO qc_geom
FROM development_tmp
WHERE ((co_earliest_effectivedate::date >= '2010-01-01' AND co_earliest_effectivedate::date <=  '2019-06-30')
OR (co_earliest_effectivedate IS NULL AND status_q::date >= '2010-01-01' AND status_q::date <=  '2019-06-30')
OR (co_earliest_effectivedate IS NULL AND status_q IS NULL AND status_a::date >= '2010-01-01' AND status_a::date <=  '2019-06-30'))
AND x_outlier IS DISTINCT FROM 'true'
;

--clean up empty values
UPDATE qc_geom 
SET geo_bbl = NULLIF(geo_bbl, ''),
    geo_bin = NULLIF(geo_bin, ''),
    geo_zipcode = NULLIF(geo_zipcode, ''),
    geo_boro = NULLIF(geo_boro, ''),
    geo_cd = NULLIF(geo_cd, ''),
    geo_council = NULLIF(geo_council, ''),
    geo_ntacode2010 = NULLIF(geo_ntacode2010, ''),
    geo_censusblock2010 = NULLIF(geo_censusblock2010, ''),
    geo_censustract2010 = NULLIF(geo_censustract2010, ''),
    geo_csd = NULLIF(geo_csd, ''),
    latitude = NULLIF(latitude, ''),
    longitude = NULLIF(longitude, '');

ALTER TABLE qc_geom
DROP COLUMN IF EXISTS bbl,
DROP COLUMN IF EXISTS bin,
DROP COLUMN IF EXISTS zipcode,
DROP COLUMN IF EXISTS boro,
DROP COLUMN IF EXISTS cd,
DROP COLUMN IF EXISTS council,
DROP COLUMN IF EXISTS ntacode2010,
DROP COLUMN IF EXISTS censusblock2010,
DROP COLUMN IF EXISTS censustract2010,
DROP COLUMN IF EXISTS csd,
DROP COLUMN IF EXISTS geom;

ALTER TABLE qc_geom
ADD bbl TEXT,
ADD bin TEXT,
ADD zipcode TEXT,
ADD boro TEXT,
ADD cd TEXT,
ADD council TEXT,
ADD ntacode2010 TEXT,
ADD censusblock2010 TEXT,
ADD censustract2010 TEXT,
ADD csd TEXT,
ADD geom GEOMETRY(POINT, 4326);

UPDATE qc_geom
SET geom = ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision),4326);

--spatial join
-- community district
UPDATE qc_geom a
	SET cd = b.borocd::text
	FROM dcp_cdboundaries b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- nta
UPDATE qc_geom a
	SET ntacode2010 = b.ntacode
	FROM dcp_ntaboundaries b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- cenus block
UPDATE qc_geom a
	SET censusblock2010 = b.cb2010
	FROM dcp_censusblocks b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- census tracts
UPDATE qc_geom a
	SET censustract2010 = b.ct2010
	FROM dcp_censustracts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- school districts
UPDATE qc_geom a
	SET csd = lpad(b.schooldist::text,2,'0')
	FROM dcp_school_districts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- borough code
UPDATE qc_geom a
	SET boro = b.borocode
	FROM dcp_boroboundaries_wi b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- council districts
UPDATE qc_geom a
	SET council = lpad(b.coundist::text,2,'0')
	FROM dcp_councildistricts b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- bbl
UPDATE qc_geom a
	SET bbl = b.bbl
	FROM dcp_mappluto b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- bin
UPDATE qc_geom a
	SET bin = b.bin
	FROM doitt_buildingfootprints b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;
-- zipcode
UPDATE qc_geom a
	SET zipcode = b.zipcode
	FROM doitt_zipcodeboundaries b
	WHERE ST_Within(a.geom,b.geom)
	AND a.geom IS NOT NULL;

DROP TABLE IF EXISTS dev_qc_geo_mismatch;
CREATE TABLE dev_qc_geo_mismatch AS (
SELECT job_number, geo_bbl,bbl, geo_bin,bin,
geo_zipcode, zipcode, geo_cd,cd,
geo_council,council, geo_ntacode2010, ntacode2010,
geo_censusblock2010, censusblock2010,
geo_censustract2010, censustract2010,
geo_csd, csd
FROM qc_geom
WHERE geom IS NOT NULL
AND (geo_bbl != bbl
OR geo_bin != bin
OR geo_zipcode != zipcode
OR geo_boro != boro
OR geo_council != council
OR geo_ntacode2010 != ntacode2010
OR geo_censusblock2010 != censusblock2010
OR geo_censustract2010 != censustract2010
OR geo_csd != csd)
);