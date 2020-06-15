#!/bin/bash
source config.sh

# dispaly "Starting to build Developments DB"
# psql $BUILD_ENGINE -f sql/_function.sql
# psql $BUILD_ENGINE -f sql/_lookup.sql
# psql $BUILD_ENGINE -f sql/_init.sql
# count _INIT_devdb

# dispaly "Geocoding Developments DB"
# docker run --rm\
#     -v $(pwd):/src\
#     -w /src\
#     -e BUILD_ENGINE=$BUILD_ENGINE\
#     sptkl/docker-geosupport:latest python3 python/geocode.py
# count _GEO_devdb

# dispaly "Assign geoms to _GEO_devdb and create GEO_devdb"
# psql $BUILD_ENGINE -f sql/_geo.sql
# count GEO_devdb

# dispaly "Fill NULLs spatial boundries in GEO_devdb through spatial joins. 
#   This is the consolidated spatial attributes table"
# psql $BUILD_ENGINE -f sql/_spatial.sql
# count SPATIAL_devdb
# count INIT_devdb

# dispaly "Adding on PLUTO columns"
# psql $BUILD_ENGINE -f sql/_pluto.sql
# count PLUTO_devdb

# dispaly "Create CO fields, effectivedate, co_earliest_effectivedate date,
#   year_complete, co_latest_effectivedate, co_latest_units, co_latest_certtype"
# psql $BUILD_ENGINE -f sql/_co.sql
# count CO_devdb

# dispaly "Creating OCC fields, occ_init, occ_prop, occ_category"
# psql $BUILD_ENGINE -f sql/_occ.sql
# count OCC_devdb

# dispaly "Creating UNITS fields, units_init, units_prop, units_net"
# psql $BUILD_ENGINE -f sql/_units.sql
# count UNITS_devdb

# dispaly "Creating status_q field, year_complete and year_permit"
# psql $BUILD_ENGINE -f sql/_status_q.sql
# count STATUS_Q_devdb

# psql $BUILD_ENGINE -f sql/_mid.sql
# count _MID_devdb

# dispaly "Creating status field, year_complete and 
#   x_inactive, x_dcpedited, x_reason"
# psql $BUILD_ENGINE -f sql/_status.sql
# psql $BUILD_ENGINE -f sql/mid.sql
# count MID_devdb
