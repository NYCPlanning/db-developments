DROP TABLE IF EXISTS DE_qaqc;

SELECT
    a.job_number,
    a.b_likely_occ_desc,
    a.b_large_alt_reduction,
    a.b_nonres_with_units,
    a.units_co_prop_mismatch,
    a.partially_complete,
    a.units_init_null,
    a.units_prop_null,
    a.units_res_accessory,
    a.outlier_demo_20plus,
    a.outlier_nb_500plus,
    a.outlier_top_alt_increase,
    a.dup_bbl_address_units,
    a.dup_bbl_address,
    a.inactive_with_update,
    a.no_work_job,
    a.geo_water,
    a.geo_taxlot,
    a.geo_null_latlong,
    a.geo_null_boundary,
    a.invalid_date_filed,
    a.invalid_date_lastupdt,
    a.invalid_date_statusd,
    a.invalid_date_statusp,
    a.invalid_date_statusr,
    a.invalid_date_statusx,
    a.incomp_tract_home,
    a.dem_nb_overlap 
INTO DE_qaqc
FROM
    FINAL_qaqc a
WHERE
    a.b_likely_occ_desc = 1
    OR a.b_large_alt_reduction = 1
    OR a.b_nonres_with_units = 1
    OR a.partially_complete = 1
    OR a.units_init_null = 1
    OR a.units_prop_null = 1
    OR a.units_res_accessory = 1
    OR a.outlier_demo_20plus = 1
    OR a.outlier_nb_500plus = 1
    OR a.outlier_top_alt_increase = 1
    OR a.inactive_with_update = 1
    OR a.no_work_job = 1
    OR a.geo_water = 1
    OR a.geo_taxlot = 1
    OR a.geo_null_latlong = 1
    OR a.geo_null_boundary = 1
    OR a.invalid_date_filed = 1
    OR a.invalid_date_lastupdt = 1
    OR a.invalid_date_statusd = 1
    OR a.invalid_date_statusp = 1
    OR a.invalid_date_statusr = 1
    OR a.invalid_date_statusx = 1
    OR a.dem_nb_overlap = 1
    OR a.dup_bbl_address_units IS NOT NULL
    OR a.dup_bbl_address IS NOT NULL
    OR a.units_co_prop_mismatch IS NOT NULL;