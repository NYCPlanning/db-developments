#!/bin/bash
source config.sh

START=$(date +%s);

echo 'Geocoding hny...'
docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/docker-geosupport:19d bash -c "python3 python/geocode_hny.py"

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

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'