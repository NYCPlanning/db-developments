#!/bin/bash
source config.sh
# some final processing is done in Esri to create the Esri file formats
# please go to NYC Planning's Bytes of the Big Apple to download the offical versions of PLUTO and MapPLUTO
# https://www1.nyc.gov/site/planning/data-maps/open-data.page

START=$(date +%s);
echo "=== Exporting QAQC CSVs ==="
psql $BUILD_ENGINE -f sql/qc_.sql
psql $BUILD_ENGINE -f sql/qc_geom.sql
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_jobtypestats) TO '$(pwd)/output/qc_jobtypestats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_countsstats) TO '$(pwd)/output/qc_countsstats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_units_complete_stats) TO '$(pwd)/output/qc_units_complete_stats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_geocodedstats) TO '$(pwd)/output/qc_geocodedstats.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_a1_units_prop) TO '$(pwd)/output/qc_a1_units_prop.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_a1_units_init) TO '$(pwd)/output/qc_a1_units_init.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hotel_resid_nb_a1) TO '$(pwd)/output/qc_hotel_resid_nb_a1.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hotel_resid_a1) TO '$(pwd)/output/qc_hotel_resid_a1.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_nonresid_large) TO '$(pwd)/output/qc_nonresid_large.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_potentialdups) TO '$(pwd)/output/qc_potentialdups.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_occupancyresearch) TO '$(pwd)/output/qc_occupancyresearch.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_hny_mismatch) TO '$(pwd)/output/qc_hny_mismatch.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_unclipped) TO '$(pwd)/output/qc_unclipped.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_cofos_units) TO '$(pwd)/output/qc_cofos_units.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_mismatch_complete_units) TO '$(pwd)/output/qc_mismatch_complete_units.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_mismatch_incomplete_units) TO '$(pwd)/output/qc_mismatch_incomplete_units.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_sro) TO '$(pwd)/output/qc_sro.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_jobnum) TO '$(pwd)/output/qc_jobnum.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_geom) TO '$(pwd)/output/qc_geom.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM dev_qc_geo_mismatch) TO '$(pwd)/output/qc_geo_mismatch.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_outliers
                                WHERE job_number NOT IN (
                                    SELECT DISTINCT job_number
                                    FROM qc_outliersacrhived
                                    WHERE outlier = 'N' OR outlier = 'C')
                                        AND job_number NOT IN (
                                            SELECT DISTINCT job_number
                                            FROM developments
                                            WHERE x_dcpedited = 'true'))
                        TO '$(pwd)/output/qc_outliers.csv' DELIMITER ',' CSV HEADER;"
psql $BUILD_ENGINE -c "\COPY (SELECT * FROM qc_outliersacrhived) TO '$(pwd)/output/qc_outliersacrhived.csv' DELIMITER ',' CSV HEADER;"

# output the aggregation table by census tract
echo "=== Exporting census tract aggregation table ==="
docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/cook:latest bash -c "python3 python/aggregate_ct.py"

psql $BUILD_ENGINE -f sql/qc_ct.sql

echo "Creating zipped shapefile"
rm output/qc_ct.zip
ogr2ogr -f "ESRI Shapefile" output/qc_ct.shp PG:$BUILD_ENGINE "qc_ct"
zip output/qc_ct.zip output/qc_ct*
rm -f output/qc_ct.shp
rm -f output/qc_ct.prj
rm -f output/qc_ct.dbf
rm -f output/qc_ct.shx

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'