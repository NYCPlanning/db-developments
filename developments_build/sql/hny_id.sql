-- Add unique id and planned_tax_benifit to the hny table
ALTER TABLE hny
    ADD hny_id text,
    ADD planned_tax_benefit text,
    ADD geom text;
UPDATE hny a
SET hny_id = md5(CAST((a.project_id,
                       a.number,
                       a.street,
                       a.geo_bin,
                       a.geo_bbl) AS text)),
    planned_tax_benefit = b.planned_tax_benefit,
    geom = (CASE WHEN a.geo_longitude != '' AND a.geo_latitude != ''
                 THEN ST_SetSRID(ST_MakePoint(a.geo_longitude::NUMERIC, 
                                   a.geo_latitude::NUMERIC),4326)
                 ELSE NULL
            END)
FROM hpd_hny_units_by_project b
WHERE a.project_id = b.project_id;