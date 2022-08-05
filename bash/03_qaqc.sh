#!/bin/bash
source bash/config.sh

display "Creating QAQC Table for init table"
psql $BUILD_ENGINE -f sql/qaqc/qaqc_init.sql

display "Creating QAQC Table for units table"
psql $BUILD_ENGINE -f sql/qaqc/qaqc_units.sql

display "Creating QAQC Table for status"
psql $BUILD_ENGINE\
  -v CAPTURE_DATE_PREV=$CAPTURE_DATE_PREV\
  -f sql/qaqc/qaqc_status.sql

display "Creating QAQC Table for qaqc mid and geo"
psql $BUILD_ENGINE -f sql/qaqc/qaqc_mid.sql
psql $BUILD_ENGINE -f sql/qaqc/qaqc_geo.sql

display "Creating QAQC Table for QAQC Application"
psql $BUILD_ENGINE -f sql/qaqc/qaqc_app_additions.sql
psql $BUILD_ENGINE -f sql/qaqc/qaqc_app.sql