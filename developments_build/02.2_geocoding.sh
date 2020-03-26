#!/bin/bash
source config.sh

START=$(date +%s);

echo 'Geocoding dev-db...'
docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/docker-geosupport:19d bash -c "python3 python/geocode.py"

psql $BUILD_ENGINE -f sql/geo_merge.sql
psql $BUILD_ENGINE -f sql/geoaddress.sql
psql $BUILD_ENGINE -f sql/geombbl.sql
# psql $BUILD_ENGINE -f sql/export.sql
psql $BUILD_ENGINE -f sql/latlong.sql
psql $BUILD_ENGINE -f sql/spatialjoins.sql
psql $BUILD_ENGINE -f sql/dedupe_job_number.sql
psql $BUILD_ENGINE -f sql/dropmillionbin.sql
psql $BUILD_ENGINE -f sql/pluto_merge.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'