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
    CSV_export EXPORT_housing &
    CSV_export EXPORT_devdb

    wait
    display "CSV Export Complete"

)

Upload latest &
Upload $VERSION &
Upload $DATE

wait 
display "Upload Complete"
