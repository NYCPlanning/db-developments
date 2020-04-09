#!/bin/bash
source config.sh

# Generate output tables
psql $BUILD_ENGINE -v VERSION=$VERSION -v CAPTURE_DATE=$CAPTURE_DATE -f sql/export.sql

mkdir -p output

# -- export
# --all records
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export) TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_developments.csv
# -- only points
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export WHERE ST_GeometryType(geom)='ST_Point') TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_developments_pts.csv
# -- records that did not geocode
psql $BUILD_ENGINE -c "\copy (SELECT * FROM devdb_export WHERE geom IS NULL AND upper(address) NOT LIKE '% TEST %') TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_developments_nogeom.csv
# -- only housing records
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export) TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_housing.csv
# -- only housing points
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export WHERE ST_GeometryType(geom)='ST_Point') TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_housing_pts.csv
# -- ony housing records that did not geocode
psql $BUILD_ENGINE -c "\copy (SELECT * FROM housing_export WHERE geom IS NULL AND upper(address) NOT LIKE '% TEST %') TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_housing_nogeom.csv

psql $BUILD_ENGINE -c "\copy (SELECT * FROM developments_co) TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_cos.csv

psql $BUILD_ENGINE -c "\copy (SELECT * FROM development_tmp) TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_geosupportoutput.csv

psql $BUILD_ENGINE -c "\copy (SELECT * FROM qc_millionbinresearch) TO stdout DELIMITER ',' CSV HEADER;" > output/qc_millionbinresearch.csv

psql $BUILD_ENGINE -c "\copy (SELECT job_number, field, old_value, new_value, reason, edited_date FROM housing_input_research) TO stdout DELIMITER ',' CSV HEADER;" > output/housing_input_research.csv
# -- output hny database

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny_job_lookup) TO stdout DELIMITER ',' CSV HEADER;" > output/hny_devdb_job_lookup.csv

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny) TO stdout DELIMITER ',' CSV HEADER;" > output/hny_devdb.csv

psql $BUILD_ENGINE -c "\copy (SELECT * FROM hny_job_unmatch) TO stdout DELIMITER ',' CSV HEADER;" > output/hny_devdb_job_unmatch.csv

# -- output yearly_unitchange table
psql $BUILD_ENGINE -c "\copy (SELECT * FROM yearly_unitchange) TO stdout DELIMITER ',' CSV HEADER;" > output/devdb_yearly_unitchange.csv

# output the updated cofos
psql $BUILD_ENGINE -c "\copy (SELECT * FROM dob_cofos) TO stdout DELIMITER ',' CSV HEADER;" > output/dob_cofos.csv