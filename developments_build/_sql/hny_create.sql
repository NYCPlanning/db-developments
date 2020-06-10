-- Append the geocode results to the hpd_hny_units_by_building
-- Limited to non-confidentital and new constructions
DROP TABLE IF EXISTS hny;
SELECT a.*, b.geo_bbl, b.geo_bin, b.geo_latitude, b.geo_longitude INTO hny
FROM hpd_hny_units_by_building a
LEFT JOIN hny_geocode_results b
ON a.ogc_fid::text = b.uid
WHERE reporting_construction_type = 'New Construction'
AND project_name <> 'CONFIDENTIAL';