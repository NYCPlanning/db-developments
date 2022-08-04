
DROP TABLE IF EXISTS qaqc_historic;
create table qaqc_historic(
    version text,
    b_likely_occ_desc integer,
    b_large_alt_reduction integer,
    b_nonres_with_units integer,
    units_co_prop_mismatch integer,
    partially_complete integer,
    units_init_null integer,
    units_prop_null integer,
    units_res_accessory integer,
    outlier_demo_20plus integer,
    outlier_nb_500plus integer,
    outlier_top_alt_increase integer,
    dup_bbl_address_units integer,
    dup_bbl_address integer,
    inactive_with_update integer,
    no_work_job integer,
    geo_water integer,
    geo_taxlot integer,
    geo_null_latlong integer,
    geo_null_boundary integer,
    invalid_date_filed integer,
    invalid_date_lastupdt integer,
    invalid_date_statusd integer,
    invalid_date_statusp integer,
    invalid_date_statusr integer,
    invalid_date_statusx integer,
    incomp_tract_home integer,
    dem_nb_overlap integer
);

-- 20Q2
DROP TABLE IF EXISTS qaqc_20Q2;

create table qaqc_20Q2(
    b_likely_occ_desc text,
    b_large_alt_reduction text,
    b_nonres_with_units text,
    units_co_prop_mismatch text,
    partially_complete text,
    units_init_null text,
    units_prop_null text,
    units_res_accessory text,
    outlier_demo_20plus text,
    outlier_nb_500plus text,
    outlier_top_alt_increase text,
    dup_bbl_address_units text,
    dup_bbl_address text,
    inactive_with_update text,
    no_work_job text,
    geo_water text,
    geo_taxlot text,
    geo_null_latlong text,
    geo_null_boundary text,
    invalid_date_filed text,
    invalid_date_lastupdt text,
    invalid_date_statusd text,
    invalid_date_statusp text,
    invalid_date_statusr text,
    invalid_date_statusx text,
    incomp_tract_home text,
    dem_nb_overlap text
);

\COPY qaqc_20Q2 FROM '.library/qaqc/20Q2/FINAL_qaqc.csv' DELIMITER ',' CSV HEADER;

INSERT INTO qaqc_historic(
SELECT
    '20Q2',
    SUM(CASE WHEN b_likely_occ_desc != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_large_alt_reduction != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_nonres_with_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_co_prop_mismatch != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN partially_complete != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_init_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_prop_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_res_accessory != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_demo_20plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_nb_500plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_top_alt_increase != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN inactive_with_update != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN no_work_job != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_water != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_taxlot != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_latlong != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_boundary != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_filed != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_lastupdt != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusd != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusp != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusr != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusx != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN incomp_tract_home != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dem_nb_overlap != '0' THEN 1 ELSE 0 END)
FROM qaqc_20q2
);

-- 20Q4
DROP TABLE IF EXISTS qaqc_20Q4;

create table qaqc_20Q4(
    b_likely_occ_desc text,
    b_large_alt_reduction text,
    b_nonres_with_units text,
    units_co_prop_mismatch text,
    partially_complete text,
    units_init_null text,
    units_prop_null text,
    units_res_accessory text,
    outlier_demo_20plus text,
    outlier_nb_500plus text,
    outlier_top_alt_increase text,
    dup_bbl_address_units text,
    dup_bbl_address text,
    inactive_with_update text,
    no_work_job text,
    geo_water text,
    geo_taxlot text,
    geo_null_latlong text,
    geo_null_boundary text,
    invalid_date_filed text,
    invalid_date_lastupdt text,
    invalid_date_statusd text,
    invalid_date_statusp text,
    invalid_date_statusr text,
    invalid_date_statusx text,
    incomp_tract_home text,
    dem_nb_overlap text
);

\COPY qaqc_20Q4 FROM '.library/qaqc/20Q4/FINAL_qaqc.csv' DELIMITER ',' CSV HEADER;

INSERT INTO qaqc_historic(
SELECT
    '20Q4',
    SUM(CASE WHEN b_likely_occ_desc != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_large_alt_reduction != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_nonres_with_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_co_prop_mismatch != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN partially_complete != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_init_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_prop_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_res_accessory != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_demo_20plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_nb_500plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_top_alt_increase != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN inactive_with_update != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN no_work_job != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_water != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_taxlot != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_latlong != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_boundary != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_filed != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_lastupdt != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusd != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusp != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusr != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusx != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN incomp_tract_home != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dem_nb_overlap != '0' THEN 1 ELSE 0 END)
FROM qaqc_20q4
);

-- 21Q2

DROP TABLE IF EXISTS qaqc_21Q2;

create table qaqc_21Q2(
    b_likely_occ_desc text,
    b_large_alt_reduction text,
    b_nonres_with_units text,
    units_co_prop_mismatch text,
    partially_complete text,
    units_init_null text,
    units_prop_null text,
    units_res_accessory text,
    outlier_demo_20plus text,
    outlier_nb_500plus text,
    outlier_top_alt_increase text,
    dup_bbl_address_units text,
    dup_bbl_address text,
    inactive_with_update text,
    no_work_job text,
    geo_water text,
    geo_taxlot text,
    geo_null_latlong text,
    geo_null_boundary text,
    invalid_date_filed text,
    invalid_date_lastupdt text,
    invalid_date_statusd text,
    invalid_date_statusp text,
    invalid_date_statusr text,
    invalid_date_statusx text,
    incomp_tract_home text,
    dem_nb_overlap text
);

\COPY qaqc_21Q2 FROM '.library/qaqc/21Q2/FINAL_qaqc.csv' DELIMITER ',' CSV HEADER;

INSERT INTO qaqc_historic(
SELECT
    '21Q2',
    SUM(CASE WHEN b_likely_occ_desc != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_large_alt_reduction != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_nonres_with_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_co_prop_mismatch != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN partially_complete != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_init_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_prop_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_res_accessory != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_demo_20plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_nb_500plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_top_alt_increase != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN inactive_with_update != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN no_work_job != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_water != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_taxlot != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_latlong != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_boundary != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_filed != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_lastupdt != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusd != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusp != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusr != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusx != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN incomp_tract_home != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dem_nb_overlap != '0' THEN 1 ELSE 0 END)
FROM qaqc_21q2
);


-- 21Q4

DROP TABLE IF EXISTS qaqc_21Q4;

create table qaqc_21Q4(
    job_number text,
    b_likely_occ_desc text,
    b_large_alt_reduction text,
    b_nonres_with_units text,
    units_co_prop_mismatch text,
    partially_complete text,
    units_init_null text,
    units_prop_null text,
    units_res_accessory text,
    outlier_demo_20plus text,
    outlier_nb_500plus text,
    outlier_top_alt_increase text,
    dup_bbl_address_units text,
    dup_bbl_address text,
    inactive_with_update text,
    no_work_job text,
    geo_water text,
    geo_taxlot text,
    geo_null_latlong text,
    geo_null_boundary text,
    invalid_date_filed text,
    invalid_date_lastupdt text,
    invalid_date_statusd text,
    invalid_date_statusp text,
    invalid_date_statusr text,
    invalid_date_statusx text,
    incomp_tract_home text,
    dem_nb_overlap text
);

\COPY qaqc_21Q4 FROM '.library/qaqc/21Q4/FINAL_qaqc.csv' DELIMITER ',' CSV HEADER;

INSERT INTO qaqc_historic(
SELECT
    '21Q4',
    SUM(CASE WHEN b_likely_occ_desc != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_large_alt_reduction != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN b_nonres_with_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_co_prop_mismatch != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN partially_complete != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_init_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_prop_null != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN units_res_accessory != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_demo_20plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_nb_500plus != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN outlier_top_alt_increase != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address_units != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dup_bbl_address != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN inactive_with_update != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN no_work_job != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_water != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_taxlot != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_latlong != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN geo_null_boundary != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_filed != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_lastupdt != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusd != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusp != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusr != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN invalid_date_statusx != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN incomp_tract_home != '0' THEN 1 ELSE 0 END),
    SUM(CASE WHEN dem_nb_overlap != '0' THEN 1 ELSE 0 END)
FROM qaqc_21q4
)