#!/bin/bash
source config.sh

docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e EDM_DATA=$EDM_DATA\
    -e RECIPE_ENGINE=$RECIPE_ENGINE\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    sptkl/cook:latest bash -c "
        python3 python/small_dataloading.py"

psql $BUILD_ENGINE -f sql/preprocessing.sql