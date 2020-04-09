#!/bin/bash
source config.sh

echo 'Build yearly_unitchange table...'
psql $BUILD_ENGINE -f sql/devdb_yoyco.sql

docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    sptkl/cook:latest bash -c "
        python3 python/yoy_table.py; 
        python3 python/yoy_table_corr.py"