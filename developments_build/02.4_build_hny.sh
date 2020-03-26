#!/bin/bash
source config.sh

START=$(date +%s);

echo '=== Geocoding hny ==='
docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/docker-geosupport:19d bash -c "python3 python/geocode_hny.py"

echo '=== Building hny database ==='
psql $BUILD_ENGINE -f sql/dob_hny_create.sql
echo 'Merge geocoding results'
psql $BUILD_ENGINE -f sql/hny_create.sql
echo 'Add unique ID and planned tax benefit'
psql $BUILD_ENGINE -f sql/hny_id.sql

echo '=== Match HNY to jobs ==='
psql $BUILD_ENGINE -f sql/hny_job_lookup.sql
echo 'Match HPD hny table'
psql $BUILD_ENGINE -f sql/hny_res_nb_match.sql
psql $BUILD_ENGINE -f sql/hny_a1_nonres_match.sql
echo 'Match manually researched hny table'
psql $BUILD_ENGINE -f sql/hny_manual_geomerge.sql
psql $BUILD_ENGINE -f sql/hny_manual_match.sql
psql $BUILD_ENGINE -f sql/hny_job_relat.sql
psql $BUILD_ENGINE -f sql/hny_many_to_many_qc.sql
psql $BUILD_ENGINE -f sql/hny_dob_match.sql
echo 'Assigning hny fields to dev-db based on matches'
psql $BUILD_ENGINE -f sql/dob_hny_id.sql
psql $BUILD_ENGINE -f sql/dob_affordable_units.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'