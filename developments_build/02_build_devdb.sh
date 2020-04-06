#!/bin/bash
source config.sh

echo "Starting to build Developments DB"
psql $BUILD_ENGINE -f sql/create.sql

# populate job application data
psql $BUILD_ENGINE -f sql/jobnumber.sql

# Remove administrative jobs 
psql $BUILD_ENGINE -f sql/adminjobs.sql

# Formating occ_init, occ_prop, units_prop, boro, 
# stories_init, zoningsft_init, zoningsft_prop
psql $BUILD_ENGINE -f sql/clean.sql

# Incorporate housing_input_research table (removing records)
psql $BUILD_ENGINE -f sql/housing_input_reasearch.sql
echo 'Transforming data attributes to DCP values'
# remove extra spaces from address number and street field
# populate the address field.
psql $BUILD_ENGINE -f sql/address.sql

# Assign jobtype
# A1 -> Alteration| DM -> Demolition | NB -> new building
psql $BUILD_ENGINE -f sql/jobtype.sql

# populate the occupancy code fields using the 
# housing_input_lookup_occupancy lookup table
psql $BUILD_ENGINE -f sql/occ_.sql

# units_init = 0 
#   1. jobtype = New Building
#   2. hotels --> multiple dwelling units
# units_prop = 0
#   1. jobtype = Demolition
#   2. multiple dwelling units --> hotels
psql $BUILD_ENGINE -f sql/units_.sql

echo 'Adding on DCP researched attributes'
# overwite DOB data with DCP researched values
# where DCP reseached value is valid
# clean the housing_input_research table
psql $BUILD_ENGINE -f sql/dcpattributes.sql

echo 'Calculating data attributes'
# statusq: date of the oldest issuance date
# year_permit: year of the status q date
# year_complete: status q year
psql $BUILD_ENGINE -f sql/statusq.sql

# units_net: proposed net change in units
#   1. demolition: units_net = units_init * -1
#   2. new building: units_net = units_prop
#   3. alteration: units_net = units_prop - units_init
psql $BUILD_ENGINE -f sql/units_net.sql

echo 'Adding on CO data attributes'
# Create the developments_co table
psql $BUILD_ENGINE -f sql/cotable.sql

# Populating co_earliest_effectivedate,
# co_latest_effectivedate, year_complete
# co_latest_certtype, co_latest_units
psql $BUILD_ENGINE -f sql/co_.sql

# Assign the status using 
# housing_input_lookup_status and other logic
psql $BUILD_ENGINE -f sql/status.sql

# set year_complete=NULL if demolition/withdrawn
psql $BUILD_ENGINE -f sql/year_complete.sql

# calculate units_complete and units_incomplete
# and incorporate housing_input_research 
psql $BUILD_ENGINE -f sql/unitscomplete.sql

echo 'Populating DCP data flags'
# Identify inactive projects and mixuse projects
psql $BUILD_ENGINE -f sql/x_inactive.sql
psql $BUILD_ENGINE -f sql/x_mixeduse.sql
# psql $BUILD_ENGINE -f sql/x_outlier.sql

echo 'Geocoding dev-db...'
# geocoding ...
docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    -d sptkl/docker-geosupport:latest bash -c "python3 python/geocode.py"

psql $BUILD_ENGINE -f sql/geo_merge.sql
psql $BUILD_ENGINE -f sql/geoaddress.sql
psql $BUILD_ENGINE -f sql/geombbl.sql
psql $BUILD_ENGINE -f sql/latlong.sql
psql $BUILD_ENGINE -f sql/spatialjoins.sql
psql $BUILD_ENGINE -f sql/dedupe_job_number.sql
psql $BUILD_ENGINE -f sql/dropmillionbin.sql
psql $BUILD_ENGINE -f sql/pluto_merge.sql