#!/bin/bash

# Setting environmental variables
function set_env {
  for envfile in $@
  do
    if [ -f $envfile ]
      then
        export $(cat $envfile | sed 's/#.*//g' | xargs)
      fi
  done
}

# Setting Environmental Variables
set_env .env version.env
DATE=$(date "+%Y-%m-%d")

function count {
  psql -d $BUILD_ENGINE -At -c "SELECT count(*) FROM $1;" | 
  while read -a count; do
  echo -e "
  \e[33m$1: $count records\e[0m
  "
  done

  ddl=$(psql -At $BUILD_ENGINE -c "SELECT get_DDL('$1') as DDL;")
  echo -e "
  \e[33m$ddl\e[0m
  "
}

# Parsing database url
function urlparse {
    proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    url=$(echo $1 | sed -e s,$proto,,g)
    userpass="$(echo $url | grep @ | cut -d@ -f1)"
    BUILD_PWD=`echo $userpass | grep : | cut -d: -f2`
    BUILD_USER=`echo $userpass | grep : | cut -d: -f1`
    hostport=$(echo $url | sed -e s,$userpass@,,g | cut -d/ -f1)
    BUILD_HOST="$(echo $hostport | sed -e 's,:.*,,g')"
    BUILD_PORT="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    BUILD_DB="$(echo $url | grep / | cut -d/ -f2-)"
}

# Pretty print messages
function display {
  echo -e "
  \e[92m\e[1m$@\e[21m\e[0m
  "
}

function CSV_export {
  psql $BUILD_ENGINE  -c "\COPY (
    SELECT * FROM $@
  ) TO STDOUT DELIMITER ',' CSV HEADER;" > $@.csv
}

function Upload {
  mc rm -r --force spaces/edm-publishing/db-developments/$@
  mc cp -r output spaces/edm-publishing/db-developments/$@
}

function imports_csv {
   cat data/$1.csv | psql $BUILD_ENGINE -c "COPY $1 FROM STDIN DELIMITER ',' CSV HEADER;"
}

function archive {
    echo "archiving $1 -> $2"
    pg_dump -t $1 $BUILD_ENGINE -O -c | psql $EDM_DATA
    psql $EDM_DATA -c "CREATE SCHEMA IF NOT EXISTS $2;";
    psql $EDM_DATA -c "ALTER TABLE $1 SET SCHEMA $2;";
    psql $EDM_DATA -c "DROP VIEW IF EXISTS $2.latest;";
    psql $EDM_DATA -c "DROP TABLE IF EXISTS $2.\"$DATE\";";
    psql $EDM_DATA -c "ALTER TABLE $2.$1 RENAME TO \"$DATE\";";
    psql $EDM_DATA -c "CREATE VIEW $2.latest AS (SELECT '$DATE' as v, * FROM $2.\"$DATE\");"
}

function SHP_export {
  urlparse $BUILD_ENGINE
  mkdir -p $@ &&
    (
      cd $@
      ogr2ogr -progress -f "ESRI Shapefile" $@.shp \
          PG:"host=$BUILD_HOST user=$BUILD_USER port=$BUILD_PORT dbname=$BUILD_DB password=$BUILD_PWD" \
          -nlt POINT $@
        rm -f $@.zip
        zip $@.zip *
        ls | grep -v $@.zip | xargs rm
      )
}
