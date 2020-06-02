-- set the geometry to be the center of the lot using lat/long
UPDATE developments a
SET geom = ST_SetSRID(ST_MakePoint(a.longitude::double precision, a.latitude::double precision),4326),
	x_geomsource = 'Lat/Long geosupport'
WHERE a.geom IS NULL
AND a.longitude IS NOT NULL AND a.longitude <> '' AND a.geo_bbl IS NOT NULL;
-- set the geometry to be the center of the lot using mappluto
UPDATE developments a
SET geom = ST_Centroid(b.geom),
	x_geomsource = 'BBL geosupport MapPLUTO'
FROM dcp_mappluto b
WHERE a.geo_bbl::text = b.bbl::text
AND a.geom IS NULL
AND b.geom IS NOT NULL;

UPDATE developments a
SET geom = ST_Centroid(b.geom),
	x_geomsource = 'BBL DOB MapPLUTO'
FROM dcp_mappluto b
WHERE a.bbl::text||'.00' = b.bbl::text
AND a.geom IS NULL
AND b.geom IS NOT NULL;

-- set the geometry to be the center of the lot using DTM
UPDATE developments a
SET geom = ST_Centroid(b.geom),
	x_geomsource = 'BBL DOB DTM'
FROM dof_dtm b
WHERE a.bbl = b.bbl
AND a.geom IS NULL
AND b.geom IS NOT NULL;