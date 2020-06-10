DROP TABLE IF EXISTS qc_ct;
CREATE TABLE qc_ct AS (
SELECT a.boro||a.ct2010 AS boroct2010, a.*, b.geom
FROM qc_aggregate_ct a
LEFT JOIN dcp_censustracts b
ON a.boro||a.ct2010 = b.boroct2010
);