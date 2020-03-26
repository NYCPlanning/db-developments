/** Match by bin&bbl, limited to residential NBs**/
WITH match AS(
    SELECT 
        h.hny_id,
        d.job_number,
        d.job_type
    FROM hny AS h
    LEFT JOIN developments_hny AS d
    ON h.geo_bbl = d.geo_bbl AND h.geo_bin = d.geo_bin
    WHERE d.job_type = 'New Building'
    AND d.occ_category = 'Residential'
    AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
    AND h.geo_bin != '' AND h.geo_bin IS NOT NULL
    AND h.geo_bbl !='' AND h.geo_bbl IS NOT NULL
    AND d.status <> 'Withdrawn'
    )
INSERT INTO hny_job_lookup (hny_id, job_number, match_method, dob_type)
SELECT m.hny_id, m.job_number, 'BINandBBL', job_type
FROM match m
WHERE CONCAT(hny_id,job_number) NOT IN (
    SELECT CONCAT(hny_id,job_number) 
    FROM hny_job_lookup)
;

/** Match by bbl only, limited to residential NBs and projects not matched by BIN&BBL**/
WITH match AS(
    SELECT 
        h.hny_id,
        d.job_number,
        d.job_type
    FROM hny AS h
    LEFT JOIN developments_hny AS d
    ON h.geo_bbl = d.geo_bbl
    WHERE d.job_type = 'New Building'
    AND d.occ_category = 'Residential'
    AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
    AND h.geo_bbl !='' AND h.geo_bbl IS NOT NULL
    AND d.status <> 'Withdrawn'
    )
INSERT INTO hny_job_lookup (hny_id, job_number, match_method, dob_type)
SELECT m.hny_id, m.job_number, 'BBLONLY', job_type
FROM match m
WHERE hny_id NOT IN (
    SELECT hny_id
    FROM hny_job_lookup
    )
AND CONCAT(hny_id,job_number) NOT IN (
    SELECT CONCAT(hny_id,job_number)
    FROM hny_job_lookup)
;

/** Match spatially, limited to residential NBs and projects not matched by bin&bbl, or bbl only**/
WITH match AS(
    SELECT 
        h.hny_id,
        d.job_number,
        d.job_type
    FROM hny AS h
    LEFT JOIN developments_hny AS d
    ON ST_DWithin(h.geom::geography, d.geom::geography, 5)
    WHERE d.job_type = 'New Building'
    AND d.occ_category = 'Residential'
    AND ABS(h.total_units::NUMERIC - d.units_prop::NUMERIC) <=5
    AND h.geom <> NULL
    AND d.geom <> NULL
    AND d.status <> 'Withdrawn'
    )
INSERT INTO hny_job_lookup (hny_id, job_number, match_method, dob_type)
SELECT m.hny_id, m.job_number, 'Spatial', job_type
FROM match m
WHERE hny_id NOT IN (
    SELECT hny_id
    FROM hny_job_lookup
    )
AND CONCAT(hny_id,job_number) NOT IN (
    SELECT CONCAT(hny_id,job_number)
    FROM hny_job_lookup
    )
;