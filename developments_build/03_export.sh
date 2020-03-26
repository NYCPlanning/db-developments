#!/bin/bash
source config.sh

START=$(date +%s);
# Generate $(pwd)/output tables
echo '=== Extracting housing from all developments, exporting ==='
psql $BUILD_ENGINE -f sql/export.sql

# -- export
echo '=== Exporting CSV outputs ==='
# --all records
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export) TO '$(pwd)/output/devdb_developments.csv' DELIMITER ',' CSV HEADER;"
# -- only points
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export WHERE ST_GeometryType(geom)='ST_Point') TO '$(pwd)/output/devdb_developments_pts.csv' DELIMITER ',' CSV HEADER;"
# -- records that did not geocode
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export WHERE geom IS NULL AND upper(address) NOT LIKE '% TEST %') TO '$(pwd)/output/devdb_developments_nogeom.csv' DELIMITER ',' CSV HEADER;"
# -- only housing records
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export) TO '$(pwd)/output/devdb_housing.csv' DELIMITER ',' CSV HEADER;"
# -- only housing points
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export WHERE ST_GeometryType(geom)='ST_Point') TO '$(pwd)/output/devdb_housing_pts.csv' DELIMITER ',' CSV HEADER;"
# -- ony housing records that did not geocode
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export WHERE geom IS NULL AND upper(address) NOT LIKE '% TEST %') TO '$(pwd)/output/devdb_housing_nogeom.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT * FROM developments_co) TO '$(pwd)/output/devdb_cos.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT * FROM development_tmp) TO '$(pwd)/output/devdb_geosupportoutput.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT * FROM qc_millionbinresearch) TO '$(pwd)/output/qc_millionbinresearch.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT job_number, field, old_value, new_value, reason, edited_date FROM housing_input_research) TO '$(pwd)/output/housing_input_research.csv' DELIMITER ',' CSV HEADER;"
# -- $(pwd)/output hny database

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny_job_lookup) TO '$(pwd)/output/hny_devdb_job_lookup.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny) TO '$(pwd)/output/hny_devdb.csv' DELIMITER ',' CSV HEADER;"

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny_job_unmatch) TO '$(pwd)/output/hny_devdb_job_unmatch.csv' DELIMITER ',' CSV HEADER;"

# -- $(pwd)/output yearly_unitchange table
psql $BUILD_ENGINE -c "\copy (SELECT * FROM yearly_unitchange) TO '$(pwd)/output/devdb_yearly_unitchange.csv' DELIMITER ',' CSV HEADER;"

# output the updated cofos
psql $BUILD_ENGINE -c "\copy (SELECT * FROM dob_cofos) TO '$(pwd)/output/dob_cofos.csv' DELIMITER ',' CSV HEADER;"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'