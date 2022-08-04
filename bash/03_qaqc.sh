#!/bin/bash
source bash/config.sh

display "Creating QAQC Table for QAQC Application"
psql $BUILD_ENGINE -f sql/qaqc/qaqc_app_additions.sql
psql $BUILD_ENGINE -f sql/qaqc/qaqc_app.sql