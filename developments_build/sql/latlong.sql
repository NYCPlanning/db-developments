-- set the latitude and longitude
UPDATE developments
SET latitude = ST_Y(geom),
	longitude = ST_X(geom)
	WHERE geom IS NOT NULL
	AND x_geomsource <> 'Lat/Long geosupport';
-- If there is no geometry but there is a lat / long then create the geometry
UPDATE developments
SET geom = ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326),
	x_geomsource = 'Lat/Long DOB'
WHERE geom IS NULL AND longitude IS NOT NULL AND longitude <> '';
-- If there is no geometry or the geometry falls in the water  
-- take the geometry from housing_input_research where there is lat and long information
DROP INDEX IF EXISTS developments_gix;
DROP INDEX IF EXISTS dcp_mappluto_gix;
CREATE INDEX developments_gix ON developments USING GIST (geom);
CREATE INDEX dcp_mappluto_gix ON dcp_mappluto USING GIST (geom);

DROP TABLE IF EXISTS dev_qc_clipped;
DROP TABLE IF EXISTS dev_qc_water;
DROP TABLE IF EXISTS dev_qc_taxlot;
DROP TABLE IF EXISTS dev_qc_unclipped;

CREATE TABLE dev_qc_clipped AS (
SELECT a.job_number||a.status_date AS id
FROM dev_export a, dcp_ntaboundaries b
WHERE ST_Within(a.geom,b.geom)
);

CREATE TABLE dev_qc_water AS (
SELECT 'in water' as type, a.* 
FROM dev_export a
LEFT JOIN dev_qc_clipped b
ON job_number||status_date = b.id
WHERE b.id IS NULL
AND geom IS NOT NULL);

DROP TABLE IF EXISTS dev_qc_clipped;
CREATE TABLE dev_qc_clipped AS (
SELECT a.job_number||a.status_date AS id
FROM dev_export a, dcp_mappluto b
WHERE ST_Within(a.geom,b.geom)
);

CREATE TABLE dev_qc_taxlot AS (
SELECT 'outside taxlot' as type, a.*
FROM dev_export a
LEFT JOIN dev_qc_clipped b
ON job_number||status_date = b.id
WHERE b.id IS NULL
AND geom IS NOT NULL 
AND job_number||status_date NOT IN (
SELECT job_number||status_date FROM dev_qc_water)
);

CREATE TABLE dev_qc_unclipped AS (
	SELECT * FROM dev_qc_water
	UNION
	SELECT * FROM dev_qc_taxlot);
DROP TABLE IF EXISTS dev_qc_clipped;
DROP TABLE IF EXISTS dev_qc_water;
DROP TABLE IF EXISTS dev_qc_taxlot;

UPDATE developments a
SET latitude = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'latitude'
AND ((a.job_number IN (SELECT job_number FROM dev_qc_unclipped)) 
	OR ((a.latitude IS NULL OR a.latitude = '') AND b.new_value IS NOT NULL)
	OR (ROUND(b.old_value::numeric,8) = ROUND(a.latitude::numeric,8)));

UPDATE developments a
SET longitude = b.new_value,
	x_dcpedited = TRUE,
	x_reason = b.reason,
	x_geomsource = 'Lat/Long DCP'
FROM housing_input_research b
WHERE a.job_number=b.job_number
AND b.field = 'longitude'
AND ((a.job_number IN (SELECT job_number FROM dev_qc_unclipped)) 
	OR ((a.longitude IS NULL OR a.longitude = '') AND b.new_value IS NOT NULL) 
	OR (ROUND(b.old_value::numeric,8) = ROUND(a.longitude::numeric,8)));

UPDATE developments
SET geom = ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)
WHERE x_geomsource = 'Lat/Long DCP';

-- DROP TABLE IF EXISTS dev_qc_unclipped;
-- DROP TABLE IF EXISTS dev_qc_clipped;

UPDATE developments
	SET x_dcpedited = 'Edited'
	WHERE x_dcpedited IS NOT NULL; 