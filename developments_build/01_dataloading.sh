#!/bin/bash
source config.sh

# docker run --rm\
#     -v $(pwd):/developments_build\
#     -w /developments_build\
#     -e EDM_DATA=$EDM_DATA\
#     -e RECIPE_ENGINE=$RECIPE_ENGINE\
#     -e BUILD_ENGINE=$BUILD_ENGINE\
#     sptkl/cook:latest bash -c "
#         python3 python/dataloading.py"

psql $BUILD_ENGINE -c '
    DROP TABLE IF EXISTS occ_lookup;
    CREATE TABLE occ_lookup(
        dob_occ text,
        occ text
    ); 

    DROP TABLE IF EXISTS status_lookup;
    CREATE TABLE status_lookup(
        dob_status text,
        status text
    );

    DROP TABLE IF EXISTS ownership_lookup;
    CREATE TABLE ownership_lookup (
        cityowned text,
        ownertype text,
        nonprofit text,
        ownership text
    );
'

imports_csv occ_lookup &
imports_csv status_lookup &
imports_csv ownership_lookup 

wait 
display "data loading is complete"