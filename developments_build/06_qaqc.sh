#!/bin/bash
source config.sh
source ./url_parse.sh $BUILD_ENGINE

DATE=$(date "+%Y-%m-%d")
mkdir -p output

echo "Exporting QAQC scripts"
psql $BUILD_ENGINE -f sql/qc_.sql
psql $BUILD_ENGINE -f sql/qc_geom.sql
psql $BUILD_ENGINE -f sql/qc_null.sql
psql $BUILD_ENGINE -f sql/qc_mismatch.sql
psql $BUILD_ENGINE -f sql/qc_completeness.sql
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_jobtypestats) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_jobtypestats.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_countsstats) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_countsstats.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_units_complete_stats) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_units_complete_stats.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_geocodedstats) TO  stdout DELIMITER ',' CSV HEADER;" > output/qc_geocodedstats.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_a1_units_prop) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_a1_units_prop.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_a1_units_init) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_a1_units_init.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hotel_resid_nb_a1) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_hotel_resid_nb_a1.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hotel_resid_a1) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_hotel_resid_a1.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_nonresid_large) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_nonresid_large.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_potentialdups) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_potentialdups.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_occupancyresearch) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_occupancyresearch.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hny_mismatch) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_hny_mismatch.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_unclipped) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_unclipped.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_cofos_units) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_cofos_units.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_mismatch_complete_units) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_mismatch_complete_units.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_mismatch_incomplete_units) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_mismatch_incomplete_units.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_sro) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_sro.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_jobnum) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_jobnum.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_geom) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_geom.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_null) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_null.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_completeness) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_completeness.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_mismatch) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_mismatch.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_geo_mismatch) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_geo_mismatch.csv

psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_outliers
                                WHERE job_number NOT IN (
                                    SELECT DISTINCT job_number
                                    FROM qc_outliersacrhived
                                    WHERE outlier = 'N' OR outlier = 'C')
                                    AND job_number NOT IN (
                                        SELECT DISTINCT job_number
                                        FROM developments
                                        WHERE x_dcpedited = 'true')) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_outliers.csv
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_outliersacrhived) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_outliersacrhived.csv

# output the aggregation table by census tract
psql $BUILD_ENGINE -f sql/qc_ct.sql

# qc_ct
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