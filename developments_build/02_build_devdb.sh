#!/bin/bash
source config.sh

# dispaly "Starting to build Developments DB"
# psql $BUILD_ENGINE -f sql/create_devdb.sql

# dispaly "Geocoding Developments DB, job_number||status_date as UID"
# docker run --rm\
#     -v $(pwd):/src\
#     -w /src\
#     -e BUILD_ENGINE=$BUILD_ENGINE\
#     sptkl/docker-geosupport:latest python3 python/geocode.py

# dispaly "Merge _INIT_devdb, GEO_devdb -> INIT_devdb,
# and remove records by job_number and BBL (using housing_input_research)"
# psql $BUILD_ENGINE -f sql/_geo.sql

# dispaly "Adding on PLUTO columns"
psql $BUILD_ENGINE -f sql/_pluto.sql

# dispaly "Create CO fields, effectivedate, co_earliest_effectivedate date,
# year_complete, co_latest_effectivedate, co_latest_units, co_latest_certtype"
# psql $BUILD_ENGINE -f sql/_co.sql

# dispaly "Creating OCC fields, occ_init, occ_prop, occ_category"
# psql $BUILD_ENGINE -f sql/_occ.sql

# dispaly "Creating UNITS fields, units_init, units_prop, units_net"
# psql $BUILD_ENGINE -f sql/_units.sql

# dispaly "Creating status_q field, year_complete and year_permit"
# psql $BUILD_ENGINE -f sql/_status_q.sql

# dispaly "Creating status field, year_complete and x_inactive, x_dcpedited, x_reason"
# psql $BUILD_ENGINE -f sql/_status.sql

# dispaly "Adding on PLUTO columns"
# psql $BUILD_ENGINE -f sql/_pluto.sql