#!/bin/bash
source config.sh

dispaly "Starting to build Developments DB"
psql $BUILD_ENGINE -f sql/create_devdb.sql
count _INIT_devdb

dispaly "Geocoding Developments DB, job_number||status_date as UID"
docker run --rm\
    -v $(pwd):/src\
    -w /src\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    sptkl/docker-geosupport:latest python3 python/geocode.py
count GEO_devdb

dispaly "Merge _INIT_devdb, GEO_devdb -> INIT_devdb,
# and remove records by job_number and BBL (using housing_input_research)"
psql $BUILD_ENGINE -f sql/_geo.sql
count INIT_devdb

dispaly "Adding on PLUTO columns"
psql $BUILD_ENGINE -f sql/_pluto.sql
count PLUTO_devdb

dispaly "Create CO fields, effectivedate, co_earliest_effectivedate date,
year_complete, co_latest_effectivedate, co_latest_units, co_latest_certtype"
psql $BUILD_ENGINE -f sql/_co.sql
count CO_devdb

dispaly "Creating OCC fields, occ_init, occ_prop, occ_category"
psql $BUILD_ENGINE -f sql/_occ.sql
count OCC_devdb

dispaly "Creating UNITS fields, units_init, units_prop, units_net"
psql $BUILD_ENGINE -f sql/_units.sql
count UNITS_devdb

dispaly "Creating status_q field, year_complete and year_permit"
psql $BUILD_ENGINE -f sql/_status_q.sql
count STATUS_Q_devdb

dispaly "Creating status field, year_complete and x_inactive, x_dcpedited, x_reason"
psql $BUILD_ENGINE -f sql/_status.sql