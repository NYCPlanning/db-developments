#!/bin/bash
source config.sh

## Default mode is EDM
MODE="${1:-edm}"

docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e EDM_DATA=$EDM_DATA\
    -e RECIPE_ENGINE=$RECIPE_ENGINE\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    -e CAPTURE_DATE=$CAPTURE_DATE\
    -e DOB_DATA_DATE=$DOB_DATA_DATE\
    nycplanning/cook:latest bash -c "python3 python/dataloading.py"

import_public dcp_mappluto &
import_public doitt_buildingfootprints &
import_public doitt_buildingfootprints_historical &
import_public doitt_zipcodeboundaries &
import_public dcp_cdboundaries &
import_public dcp_censusblocks &
import_public dcp_censustracts &
import_public dcp_school_districts &
import_public dcp_boroboundaries_wi &
import_public dcp_councildistricts &
import_public dcp_firecompanies &
import_public dcp_policeprecincts &

case $MODE in
    weekly) 
        import_public dob_permitissuance
        import_public dob_jobapplications
    ;;
    edm) 
        import_public dob_permitissuance $DOB_DATA_DATE
        import_public dob_jobapplications $DOB_DATA_DATE
    ;;
esac

psql $BUILD_ENGINE -f sql/_create.sql

wait 
display "data loading is complete"