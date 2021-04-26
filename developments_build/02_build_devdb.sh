#!/bin/bash
source config.sh

# display "Starting to build Developments DB"
# psql $BUILD_ENGINE -f sql/_function.sql
psql $BUILD_ENGINE -f sql/_procedures.sql
psql $BUILD_ENGINE -f sql/_init.sql
# psql $BUILD_ENGINE -f sql/qaqc/qaqc_init.sql
# count _INIT_devdb

# display "Geocoding Developments DB and HNY"
# docker run --rm\
#     -v $(pwd):/src\
#     -w /src\
#     -e BUILD_ENGINE=$BUILD_ENGINE\
#     nycplanning/docker-geosupport:$VERSION_GEO bash -c "
#       python3 python/geocode.py
#       python3 python/geocode_hny.py
#     "
# count _GEO_devdb

# display "Assign geoms to _GEO_devdb and create GEO_devdb"
# psql $BUILD_ENGINE -f sql/_geo.sql
# count GEO_devdb

# display "Fill NULLs spatial boundries in GEO_devdb through spatial joins. 
#   This is the consolidated spatial attributes table"
# psql $BUILD_ENGINE -f sql/_spatial.sql
# count SPATIAL_devdb
# psql $BUILD_ENGINE -f sql/init.sql
# count INIT_devdb

# display "Adding on PLUTO columns"
# psql $BUILD_ENGINE -f sql/_pluto.sql
# count PLUTO_devdb

# display "Create CO fields: 
#       effectivedate, 
#       date_complete
#       year_complete, 
#       co_latest_effectivedate, 
#       co_latest_units, 
#       co_latest_certtype"
# psql $BUILD_ENGINE -f sql/_co.sql
# count CO_devdb

# display "Creating OCC fields: 
#       occ_initial, 
#       occ_proposed"
# psql $BUILD_ENGINE -f sql/_occ.sql
# count OCC_devdb

# display "Creating temp UNITS fields: _classa_init,
#       _classa_prop,
#       _hotel_init,
#       _hotel_prop,
#       _otherb_init,
#       _otherb_prop,
#       _classa_net,
#       resid_flag, 
#       nonres_flag"
# psql $BUILD_ENGINE -f sql/_units.sql
# psql $BUILD_ENGINE -f sql/qaqc/qaqc_units.sql
# count UNITS_devdb

# display "Creating status_q fields: date_permittd,
#       permit_year,
#       permit_qrtr,
#       _complete_year,
#       _complete_qrtr"
# psql $BUILD_ENGINE -f sql/_status_q.sql
# count STATUS_Q_devdb

# display "Combining INIT_devdb with OCC_devdb, 
#       PLUTO_devdb, 
#       CO_devdb, 
#       OCC_devdb, 
#       UNITS_devdb,
#       STATUS_Q_devdb to create _MID_devdb"
# psql $BUILD_ENGINE -f sql/_mid.sql
# count _MID_devdb

# display "Creating status fields: 
#       job_status,
#       date_lastupdt,
#       date_permittd,
#       job_inactive"

# psql $BUILD_ENGINE\
#   -v CAPTURE_DATE=$CAPTURE_DATE\
#   -f sql/_status.sql
  
# psql $BUILD_ENGINE\
#   -v CAPTURE_DATE_PREV=$CAPTURE_DATE_PREV\
#   -f sql/qaqc/qaqc_status.sql

# display "Combining _MID_devdb with STATUS_devdb to create MID_devdb"
# display "Creating final UNITS fields:
#       classa_init,
#       classa_prop,
#       hotel_init,
#       hotel_prop,
#       otherb_init,
#       otherb_prop,
#       classa_net"
# psql $BUILD_ENGINE -f sql/mid.sql
# psql $BUILD_ENGINE -f sql/qaqc/qaqc_mid.sql
# psql $BUILD_ENGINE -f sql/qaqc/qaqc_geo.sql
# count MID_devdb

# display "Creating HNY fields: 
#       hny_id,
#       classa_hnyaff,
#       all_hny_units,
#       hny_jobrelate"
# psql $BUILD_ENGINE -f sql/_hny.sql
# count HNY_devdb

# display "Creating FINAL_devdb and formatted QAQC table"
# psql $BUILD_ENGINE -v VERSION=$VERSION  -f sql/final.sql
# psql $BUILD_ENGINE -f sql/qaqc/qaqc_final.sql

# display "Creating aggregate tables"
# psql $BUILD_ENGINE -v CAPTURE_DATE=$CAPTURE_DATE -f sql/yearly.sql
# psql $BUILD_ENGINE -f sql/aggregate.sql