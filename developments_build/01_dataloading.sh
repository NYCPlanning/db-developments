#!/bin/bash
source config.sh

# psql $BUILD_ENGINE -f sql/drop_idx.sql

docker run --rm\
    -v `pwd`:/home/developments_build\
    -w /home/developments_build\
    --env-file .env\
    sptkl/cook:latest bash -c "python3 python/small_dataloading.py; python/large_dataloading.py"

psql $BUILD_ENGINE -f sql/preprocessing.sql