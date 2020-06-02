#!/bin/bash
source config.sh

echo "
    Starting to build Developments DB
"
psql $BUILD_ENGINE -f sql/create_devdb.sql
psql $BUILD_ENGINE -f sql/create_devco.sql

echo "
    Removing records with 'BIS TEST' in job description
"
psql $BUILD_ENGINE -f sql/research_removal.sql

echo "
    Creating OCC fields, occ_init, occ_prop, occ_category
"
psql $BUILD_ENGINE -f sql/_occ.sql

echo "
    Creating UNITS fields, units_init, units_prop, units_net
"
psql $BUILD_ENGINE -f sql/_units.sql

echo "
    Creating status_q field, year_complete and year_permit
"
psql $BUILD_ENGINE -f sql/_status_q.sql