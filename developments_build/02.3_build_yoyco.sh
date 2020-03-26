#!/bin/bash
source config.sh

START=$(date +%s);
echo '=== Build yearly_unitchange table ==='
psql $BUILD_ENGINE -f sql/devdb_yoyco.sql

docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/cook:latest bash -c "python3 python/yoy_table.py; python3 python/yoy_table_corr.py"

END=$(date +%s);
echo $((END-START)) | awk '{print int($1/60)" minutes and "int($1%60)" seconds elapsed."}'