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
   cat data/$1.csv | psql $BUILD_ENGINE -c "COPY $1 FROM STDIN WITH DELIMITER ',' NULL '' CSV HEADER;"
}

function import_public {
  name=$1
  version=${2:-latest}
  url=https://nyc3.digitaloceanspaces.com/edm-recipes
  version=$(curl -s $url/datasets/$name/$version/config.json | jq -r '.dataset.version')
  echo "🔵 $name version: $version"

  target_dir=$(pwd)/.library/datasets/$name/$version

  # Download sql dump for the datasets from data library
  if [ -f $target_dir/$name.sql ]; then
    echo "✅ $name.sql exists in cache"
  else
    echo "🛠 $name.sql doesn't exists in cache, downloading ..."
    mkdir -p $target_dir && (
      cd $target_dir
      curl -ss -O $url/datasets/$name/$version/$name.sql
    )
  fi

  # Loading into Database
  psql $BUILD_ENGINE -f $target_dir/$name.sql
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
        zip -9 $@.zip *
        ls | grep -v $@.zip | xargs rm
      )
}

function makevalid {
  psql $BUILD_ENGINE -c "
      UPDATE $1
      SET wkb_geometry = st_makevalid(wkb_geometry);
  "
}

function max_bg_procs {
    if [[ $# -eq 0 ]] ; then
            echo "Usage: max_bg_procs NUM_PROCS.  Will wait until the number of background (&)"
            echo "           bash processes (as determined by 'jobs -pr') falls below NUM_PROCS"
            return
    fi
    local max_number=$((0 + ${1:-0}))
    while true; do
            local current_number=$(jobs -pr | wc -l)
            if [[ $current_number -lt $max_number ]]; then
                    break
            fi
            sleep 1
    done
}