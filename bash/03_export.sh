#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source $CURRENT_DIR/config.sh

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
    SHP_export SHP_housing &

    CSV_export EXPORT_devdb &
    SHP_export SHP_devdb &

    display "Export 6 aggregate tables"
    CSV_export aggregate_block &
    CSV_export aggregate_commntydst &
    CSV_export aggregate_councildst &
    CSV_export aggregate_nta &
    CSV_export aggregate_puma &
    CSV_export aggregate_tract 
    
    display "Export QAQC Tables"
    CSV_export FINAL_qaqc &
    CSV_export HNY_no_match
    
    display "Export Corrections"
    CSV_export CORR_hny_matches &
    CSV_export corrections_applied &
    CSV_export corrections_not_applied &
    CSV_export manual_corrections 

    wait
    display "CSV Export Complete"
    echo "[$(date)] $VERSION" > version.txt
)

zip -r output/output.zip output

Upload latest &
Upload $VERSION &
Upload $DATE

wait 
display "Upload Complete"
