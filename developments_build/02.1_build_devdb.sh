#!/bin/bash
source config.sh

START=$(date +%s);

echo "Starting to build Developments DB"
psql $BUILD_ENGINE -f sql/create.sql

# populate job application data
psql $BUILD_ENGINE -f sql/jobnumber.sql
psql $BUILD_ENGINE -f sql/adminjobs.sql
psql $BUILD_ENGINE -f sql/clean.sql
psql $BUILD_ENGINE -f sql/housing_input_reasearch.sql
echo 'Transforming data attributes to DCP values'
psql $BUILD_ENGINE -f sql/bbl.sql
psql $BUILD_ENGINE -f sql/address.sql
psql $BUILD_ENGINE -f sql/jobtype.sql
psql $BUILD_ENGINE -f sql/occ_.sql
psql $BUILD_ENGINE -f sql/units_.sql


## pull out records with a specific occupancy code for manual research
## occupancy codes: A-3 (ASSEMBLY: OTHER), H-2 (HIGH HAZARD: ACCELERATED BURNING)
echo 'Outputting records for research'
## move to QA/QC scripts 

echo 'Adding on DCP researched attributes'
psql $BUILD_ENGINE -f sql/dcpattributes.sql

# echo 'Calculating data attributes'
psql $BUILD_ENGINE -f sql/statusq.sql
psql $BUILD_ENGINE -f sql/units_net.sql

echo 'Adding on CO data attributes'
psql $BUILD_ENGINE -f sql/cotable.sql
psql $BUILD_ENGINE -f sql/co_.sql
psql $BUILD_ENGINE -f sql/status.sql
psql $BUILD_ENGINE -f sql/year_complete.sql
psql $BUILD_ENGINE -f sql/unitscomplete.sql

# echo 'Outputting records for research'
# psql $BUILD_ENGINE -f sql/qc_outlier.sql

echo 'Populating DCP data flags'
psql $BUILD_ENGINE -f sql/x_inactive.sql
psql $BUILD_ENGINE -f sql/x_mixeduse.sql
# psql $BUILD_ENGINE -f sql/x_outlier.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'