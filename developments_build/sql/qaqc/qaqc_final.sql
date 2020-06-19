/*
Alphabetize QAQC table for export
*/

DROP TABLE IF EXISTS FINAL_qaqc;
SELECT job_number,
        b_large_alt_reduction,
        b_likely_occ_desc,
        b_nonres_with_units,
        dem_nb_overlap,
        dup_bbl_address,
        dup_bbl_address_units,
        greatest_alt_net_dec,
        invalid_date_filed,
        invalid_date_lastupdt,
        invalid_date_statusd,
        invalid_date_statusp,
        invalid_date_statusr,
        invalid_date_statusx,
        outlier_demo_20plus,
        outlier_nb_500plus,
        outlier_top_alt_decrease,
        outlier_top_alt_increase,
        units_co_prop_mismatch,
        units_init_null,
        units_prop_null,
        units_res_accessory,
        z_inactive_with_update,
        z_incomp_tract_home
INTO FINAL_qaqc
FROM MID_qaqc;