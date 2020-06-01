#!/bin/bash
source config.sh

mkdir -p output

echo "Exporting QAQC scripts"
psql $BUILD_ENGINE -f sql/qc_.sql
psql $BUILD_ENGINE -f sql/qc_geom.sql
psql $BUILD_ENGINE -f sql/qc_null.sql
psql $BUILD_ENGINE -f sql/qc_mismatch.sql
psql $BUILD_ENGINE -f sql/qc_completeness.sql

function export_csv {
    psql $BUILD_ENGINE -c "\COPY (
        SELECT * FROM $1
    ) TO stdout DELIMITER ',' CSV HEADER;" > output/$1.csv

}

export_csv dev_qc_jobtypestats &
export_csv dev_qc_countsstats &
export_csv dev_qc_units_complete_stats &
export_csv dev_qc_geocodedstats &
export_csv dev_qc_a1_units_prop &
export_csv dev_qc_a1_units_init &
export_csv dev_qc_hotel_resid_nb_a1 &
export_csv dev_qc_hotel_resid_a1 &
export_csv dev_qc_nonresid_large &
export_csv dev_qc_potentialdups &
export_csv dev_qc_occupancyresearch &
export_csv dev_qc_hny_mismatch &
export_csv dev_qc_unclipped &
export_csv dev_qc_cofos_units &
export_csv dev_qc_mismatch_complete_units &
export_csv dev_qc_mismatch_incomplete_units &
export_csv dev_qc_sro &
export_csv dev_qc_jobnum &
export_csv qc_geom &
export_csv qc_null &
export_csv qc_completeness &
export_csv qc_mismatch &
export_csv dev_qc_geo_mismatch &
export_csv qc_outliersacrhived &

psql $BUILD_ENGINE -c "\COPY (
    SELECT * FROM qc_outliers
    WHERE job_number NOT IN (
        SELECT DISTINCT job_number
        FROM qc_outliersacrhived
        WHERE outlier = 'N' OR outlier = 'C')
        AND job_number NOT IN (
            SELECT DISTINCT job_number
            FROM developments
            WHERE x_dcpedited = 'true')
) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_outliers.csv

wait
# output the aggregation table by census tract
psql $BUILD_ENGINE -f sql/qc_ct.sql

# qc_ct
urlparse $BUILD_ENGINE
mkdir -p output/qc_ct && 
    (cd output/qc_ct
        pgsql2shp -u $BUILD_USER -h $BUILD_HOST -p $BUILD_PORT -P $BUILD_PWD -f qc_ct $BUILD_DB \
        "SELECT * FROM qc_ct"
        rm -f qc_ct.zip
        echo "$DATE" > version.txt
        zip qc_ct.zip *
        ls | grep -v qc_ct.zip | xargs rm
    )

# Export to Spaces
zip -r output.zip output

mc rm -r --force spaces/edm-publishing/db-developments/latest
mc rm -r --force spaces/edm-publishing/db-developments/$DATE
mc cp -r output spaces/edm-publishing/db-developments/latest
mc cp -r output spaces/edm-publishing/db-developments/$DATE
mc cp output.zip spaces/edm-publishing/db-developments/latest
mc cp output.zip spaces/edm-publishing/db-developments/$DATE