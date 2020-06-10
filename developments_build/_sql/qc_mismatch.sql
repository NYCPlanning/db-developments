DROP TABLE IF EXISTS qc_mismatch;

select * into qc_mismatch from (
(SELECT 'total' AS variable, COUNT(*) AS mismatch_count FROM qc_geom)
UNION
(SELECT 'bbl' AS variable, count(nullif(geo_bbl = bbl, true)) FROM qc_geom)
UNION
(SELECT 'bin' AS variable, count(nullif(geo_bin = bin, true)) FROM qc_geom)
UNION
(SELECT 'community district' AS variable, count(nullif(geo_cd = cd, true)) FROM qc_geom)
UNION
(SELECT 'council' AS variable, count(nullif(geo_council = council, true)) FROM qc_geom)
UNION
(SELECT 'borough' AS variable, count(nullif(geo_boro = boro, true)) FROM qc_geom)
UNION
(SELECT 'ntacode2010' AS variable, count(nullif(geo_ntacode2010 = ntacode2010, true)) FROM qc_geom)
UNION
(SELECT 'censusblock2010' AS variable, count(nullif(geo_censusblock2010 = censusblock2010, true)) FROM qc_geom)
UNION
(SELECT 'censustract2010' AS variable, count(nullif(geo_censustract2010 = censustract2010, true)) FROM qc_geom
WHERE geo_censustract2010 != '000000')
UNION
(SELECT 'school district' AS variable, count(nullif(geo_csd = csd, true)) FROM qc_geom)
ORDER BY mismatch_count DESC) a;