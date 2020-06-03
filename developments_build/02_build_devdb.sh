#!/bin/bash
source config.sh

dispaly "Starting to build Developments DB"
psql $BUILD_ENGINE -f sql/INIT_devdb.sql

dispaly "Removing records with 'BIS TEST' in job description"
psql $BUILD_ENGINE -f sql/research_removal.sql

dispaly "Create CO fields, effectivedate, co_earliest_effectivedate date,
    year_complete, co_latest_effectivedate, co_latest_units, co_latest_certtype"
psql $BUILD_ENGINE -f sql/_co.sql

dispaly "Creating OCC fields, occ_init, occ_prop, occ_category"
psql $BUILD_ENGINE -f sql/_occ.sql

dispaly "Creating UNITS fields, units_init, units_prop, units_net"
psql $BUILD_ENGINE -f sql/_units.sql

dispaly "Creating status_q field, year_complete and year_permit"
psql $BUILD_ENGINE -f sql/_status_q.sql

dispaly "Creating status field, year_complete and year_permit"
psql $BUILD_ENGINE -f sql/_status.sql