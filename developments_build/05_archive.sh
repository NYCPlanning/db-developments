#!/bin/bash
source config.sh
DATE=$(date "+%Y/%m/%d");

# archive developments DB
pg_dump -t devdb_export --no-owner $BUILD_ENGINE | psql $EDM_DATA
psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS developments;";
psql $EDM_DATA -c "ALTER TABLE devdb_export SET SCHEMA developments;";
psql $EDM_DATA -c "DROP VIEW IF EXISTS developments.latest;";
psql $EDM_DATA -c "DROP TABLE IF EXISTS developments.\"$DATE\";";
psql $EDM_DATA -c "ALTER TABLE developments.devdb_export RENAME TO \"$DATE\";";
psql $EDM_DATA -c "CREATE VIEW developments.latest AS (SELECT '$DATE' as v, * FROM developments.\"$DATE\");"

# archive housing DB
pg_dump -t housing_export --no-owner $BUILD_ENGINE | psql $EDM_DATA
psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS dcp_housing;";
psql $EDM_DATA -c "ALTER TABLE housing_export SET SCHEMA dcp_housing;";
psql $EDM_DATA -c "DROP VIEW IF EXISTS dcp_housing.latest;";
psql $EDM_DATA -c "DROP TABLE IF EXISTS dcp_housing.\"$DATE\";";
psql $EDM_DATA -c "ALTER TABLE dcp_housing.housing_export RENAME TO \"$DATE\";";
psql $EDM_DATA -c "CREATE VIEW dcp_housing.latest AS (SELECT '$DATE' as v, * FROM dcp_housing.\"$DATE\");"

# archive yearly_unitchange table
pg_dump -t yearly_unitchange --no-owner $BUILD_ENGINE | psql $EDM_DATA
psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS yearly_unitchange;";
psql $EDM_DATA -c "ALTER TABLE yearly_unitchange SET SCHEMA yearly_unitchange;";
psql $EDM_DATA -c "DROP VIEW IF EXISTS yearly_unitchange.latest;";
psql $EDM_DATA -c "DROP TABLE IF EXISTS yearly_unitchange.\"$DATE\";";
psql $EDM_DATA -c "ALTER TABLE yearly_unitchange.yearly_unitchange RENAME TO \"$DATE\";";
psql $EDM_DATA -c "CREATE VIEW yearly_unitchange.latest AS (SELECT '$DATE' as v, * FROM yearly_unitchange.\"$DATE\");"
