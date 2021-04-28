#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source $CURRENT_DIR/config.sh

## Default mode is EDM
MODE="${1:-edm}"

max_bg_procs 5
import_public council_members &
import_public doe_school_subdistricts &
import_public doe_eszones &
import_public doe_mszones &
import_public hpd_hny_units_by_building &
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
import_public dob_cofos &
import_public dof_shoreline &

case $MODE in
    weekly) 
        import_public dob_permitissuance &
        import_public dob_jobapplications &
    ;;
    edm) 
        import_public dob_permitissuance $DOB_DATA_DATE &
        import_public dob_jobapplications $DOB_DATA_DATE &
    ;;
esac

psql $BUILD_ENGINE -f sql/_create.sql 

wait 
display "data loading is complete"