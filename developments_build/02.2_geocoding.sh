#!/bin/bash
source config.sh

START=$(date +%s);

echo '=== Geocoding dev-db ==='
docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/docker-geosupport:19d bash -c "python3 python/geocode.py"

echo 'Merging geosupport results'
psql $BUILD_ENGINE -f sql/geo_merge.sql
psql $BUILD_ENGINE -f sql/geoaddress.sql
echo 'Setting geometries to center of BBL'
psql $BUILD_ENGINE -f sql/geombbl.sql
#psql $BUILD_ENGINE -f sql/export.sql
echo 'Setting missing geometries with lat/lon'
psql $BUILD_ENGINE -f sql/latlong.sql
echo 'Filling in missing attributes with spatial joins'
psql $BUILD_ENGINE -f sql/spatialjoins.sql
echo 'Deduping'
psql $BUILD_ENGINE -f sql/dedupe_job_number.sql
echo 'Removing million BINs'
psql $BUILD_ENGINE -f sql/dropmillionbin.sql
echo 'Merging with PLUTO'
psql $BUILD_ENGINE -f sql/pluto_merge.sql

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'