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

psql $BUILD_ENGINE -c "
    DROP TABLE IF EXISTS lookup_occ;
    CREATE TABLE lookup_occ(
        dob_occ text,
        occ text
    ); 

    DROP TABLE IF EXISTS lookup_status;
    CREATE TABLE lookup_status(
        dob_status text,
        status text
    );

    DROP TABLE IF EXISTS lookup_ownership;
    CREATE TABLE lookup_ownership (
        cityowned text,
        ownertype text,
        nonprofit text,
        ownership text
    );

    DROP TABLE IF EXISTS housing_input_research;
    CREATE TABLE housing_input_research (
        job_number text,
        field text,
        old_value text,
        new_value text,
        reason text,
        edited_date text
    );

    DROP TABLE IF EXISTS housing_input_hny;
    CREATE TABLE housing_input_hny (
        job_number text,
        hny_id text
    );

"

imports_csv lookup_occ &
imports_csv lookup_status &
imports_csv lookup_ownership &
imports_csv housing_input_research &
imports_csv housing_input_hny 


wait 
display "data loading is complete"