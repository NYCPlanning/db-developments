#!/bin/bash
source config.sh

display "Generate output tables"
psql $BUILD_ENGINE\
    -v VERSION=$VERSION\
    -v CAPTURE_DATE=$CAPTURE_DATE\
    -f sql/_export.sql

mkdir -p output 
(
    cd output

    display "Export Devdb and HousingDB"
    CSV_export EXPORT_housing &
    SHP_export EXPORT_housing &

    CSV_export EXPORT_devdb &
    SHP_export EXPORT_devdb &

    display "Export no geom records for Devdb and HousingDB"
    psql $BUILD_ENGINE  -c "\COPY (
        SELECT * FROM EXPORT_housing
        WHERE geom is null
    ) TO STDOUT DELIMITER ',' CSV HEADER;" > EXPORT_housing_nogeom.csv &

    psql $BUILD_ENGINE  -c "\COPY (
        SELECT * FROM EXPORT_devdb
        WHERE geom is null
    ) TO STDOUT DELIMITER ',' CSV HEADER;" > EXPORT_devdb_nogeom.csv &

    display "Export 6 aggregate tables"
    CSV_export aggregate_block &
    CSV_export aggregate_comunitydist &
    CSV_export aggregate_councildist &
    CSV_export aggregate_nta &
    CSV_export aggregate_puma &
    CSV_export aggregate_tract 

    wait
    display "CSV Export Complete"

)

zip -r output/output.zip output

Upload latest &
Upload $VERSION &
Upload $DATE

wait 
display "Upload Complete"