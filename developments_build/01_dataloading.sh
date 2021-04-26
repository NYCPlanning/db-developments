#!/bin/bash
source config.sh

## Default mode is EDM
MODE="${1:-edm}"

docker run --rm\
    -v $(pwd):/developments_build\
    -w /developments_build\
    -e EDM_DATA=$EDM_DATA\
    -e RECIPE_ENGINE=$RECIPE_ENGINE\
    -e BUILD_ENGINE=$BUILD_ENGINE\
    -e CAPTURE_DATE=$CAPTURE_DATE\
    -e DOB_DATA_DATE=$DOB_DATA_DATE\
    nycplanning/cook:latest bash -c "
        python3 python/dataloading.py $MODE"

case $MODE in 
    weekly) 
        curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dob_permitissuance/latest/dob_permitissuance.sql
        curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dob_jobapplications/latest/dob_jobapplications.sql
    ;;
    edm) 
        curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dob_permitissuance/$DOB_DATA_DATE/dob_permitissuance.sql
        curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/dob_jobapplications/$DOB_DATA_DATE/dob_jobapplications.sql
    ;;
esac

psql $BUILD_ENGINE -f dob_permitissuance.sql
psql $BUILD_ENGINE -f dob_jobapplications.sql

rm dob_permitissuance.sql
rm dob_jobapplications.sql

psql $BUILD_ENGINE -c "
    DROP TABLE IF EXISTS lookup_occ;
    CREATE TABLE lookup_occ(
        dob_occ text,
        occ text
    ); 

    DROP TABLE IF EXISTS lookup_ownership;
    CREATE TABLE lookup_ownership (
        cityowned text,
        ownertype text,
        nonprofit text,
        ownership text
    );

    DROP TABLE IF EXISTS manual_corrections;
    CREATE TABLE manual_corrections (
        build_dt timestamp with time zone,
        job_number text,
        field text,
        old_value text,
        current_value text,
        new_value text,
        corr_applied text,
        reason text,
        edited_date text,
        editor text,
        job_in_devdb text
    );

    DROP TABLE IF EXISTS CORR_hny_matches;
    CREATE TABLE CORR_hny_matches (
        hny_id text,
        job_number text,
		hny_project_id text,
		action text
    );

    DROP TABLE IF EXISTS housing_input_hny;
    CREATE TABLE housing_input_hny (
        job_number text,
        hny_id text
    );

    DROP TABLE IF EXISTS census_units10;
    CREATE TABLE census_units10 (
        CenBlock10 text,
        CenTract10 text,
        NTA10 text,
        PUMA10 text,
        CenUnits10 numeric
    );

    DROP TABLE IF EXISTS census_units10adj;
    CREATE TABLE census_units10adj (
        BCT2010 text,
        CenTract10 text,
        NTA10 text,
        PUMA10 text,
        AdjUnits10 numeric
    );

    DROP TABLE IF EXISTS lookup_geo;
    CREATE TABLE lookup_geo (
        boro text,
        borocode text,
        fips_boro text,
        ctcb2010 text,
        ct2010 text,
        bctcb2010 text,
        bct2010 text,
        puma text,
        pumaname text,
        nta text,
        ntaname text,
        commntydst text,
        councildst text
    );
"

imports_csv lookup_occ &
imports_csv lookup_ownership &
imports_csv manual_corrections &
imports_csv CORR_hny_matches &
imports_csv census_units10 &
imports_csv census_units10adj &
imports_csv lookup_geo

wait 
display "data loading is complete"

 tables=(
      "dof_shoreline" 
      "dcp_mappluto"
      "doitt_buildingfootprints"
      "doitt_buildingfootprints_historical"
      "doitt_zipcodeboundaries"
      "dcp_cdboundaries"
      "dcp_censusblocks"
      "dcp_censustracts"
      "dcp_school_districts"
      "dcp_boroboundaries_wi"
      "dcp_councildistricts"
      "dcp_firecompanies"
      "doe_school_subdistricts"
      "doe_eszones"
      "doe_mszones"
      "dcp_policeprecincts"
)
for i in "${tables[@]}"
do
    makevalid $i &
done

wait 
display "all geometries valid"