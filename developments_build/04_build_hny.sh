#!/bin/bash
source config.sh

echo 'Geocoding hny...'
docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    sptkl/docker-geosupport:latest bash -c "
        python3 python/geocode_hny.py"

echo 'starting to build HNY database'
psql $BUILD_ENGINE -f sql/dob_hny_create.sql
psql $BUILD_ENGINE -f sql/hny_create.sql
psql $BUILD_ENGINE -f sql/hny_id.sql
psql $BUILD_ENGINE -f sql/hny_job_lookup.sql
psql $BUILD_ENGINE -f sql/hny_res_nb_match.sql
psql $BUILD_ENGINE -f sql/hny_a1_nonres_match.sql
psql $BUILD_ENGINE -f sql/hny_manual_geomerge.sql
psql $BUILD_ENGINE -f sql/hny_manual_match.sql
psql $BUILD_ENGINE -f sql/hny_job_relat.sql
psql $BUILD_ENGINE -f sql/hny_many_to_many_qc.sql
psql $BUILD_ENGINE -f sql/hny_dob_match.sql
psql $BUILD_ENGINE -f sql/dob_hny_id.sql
psql $BUILD_ENGINE -f sql/dob_affordable_units.sql