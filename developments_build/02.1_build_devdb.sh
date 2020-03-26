#!/bin/bash
source config.sh

START=$(date +%s);

echo "Starting to build Developments DB"
psql $BUILD_ENGINE -f sql/create.sql

# populate job application data
echo '=== Populating with DOB job application data ==='
echo 'Job numbers'
psql $BUILD_ENGINE -f sql/jobnumber.sql
echo 'Removeing admin jobs'
psql $BUILD_ENGINE -f sql/adminjobs.sql
echo 'Cleaning'
psql $BUILD_ENGINE -f sql/clean.sql
echo 'Removing records deleted in housing_input_research'
psql $BUILD_ENGINE -f sql/housing_input_reasearch.sql
echo '=== Transforming data attributes to DCP language ==='
echo 'Populating BBL'
psql $BUILD_ENGINE -f sql/bbl.sql
echo 'Cleaning addresses'
psql $BUILD_ENGINE -f sql/address.sql
echo 'Transforming job types to DCP-preferred values'
psql $BUILD_ENGINE -f sql/jobtype.sql
echo 'Set occ values using housing_input_research'
psql $BUILD_ENGINE -f sql/occ_.sql
echo 'Set unit values using housing_input_research'
psql $BUILD_ENGINE -f sql/units_.sql

echo 'Overwriting other attributed with DCP-researched values'
psql $BUILD_ENGINE -f sql/dcpattributes.sql

# echo 'Calculating data attributes'
psql $BUILD_ENGINE -f sql/statusq.sql
psql $BUILD_ENGINE -f sql/units_net.sql

echo 'Adding on certificate of occupancy data attributes'
psql $BUILD_ENGINE -f sql/cotable.sql
psql $BUILD_ENGINE -f sql/co_.sql
psql $BUILD_ENGINE -f sql/status.sql
psql $BUILD_ENGINE -f sql/year_complete.sql
psql $BUILD_ENGINE -f sql/unitscomplete.sql

echo 'Populating DCP data flags: inactive and mixed use'
psql $BUILD_ENGINE -f sql/x_inactive.sql
psql $BUILD_ENGINE -f sql/x_mixeduse.sql
# psql $BUILD_ENGINE -f sql/x_outlier.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'