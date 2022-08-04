#!/bin/bash
source bash/config.sh

function import_QAQC {
  version=$1

  target_dir=$(pwd)/.library/qaqc/$version
  qaqc_do_path=spaces/edm-publishing/db-developments/$version/output/FINAL_qaqc.csv
  if [ -f $target_dir/FINAL_qaqc.csv ]; then
    echo "✅ $version exists in cache"
  else
    echo "🛠 $version doesn't exists in cache, downloading ..."
    mkdir -p $target_dir && (
      cd $target_dir
      mc cp $qaqc_do_path FINAL_qaqc.csv
    )
  fi
}

function load_to_DB {
    psql $BUILD_ENGINE -f sql/qaqc/qaqc_historic.sql
}



for version in 20Q2 20Q4 21Q2 21Q4 
do 
 import_QAQC $version
done

load_to_DB 

mkdir -p output 
(
    cd output
    psql $BUILD_ENGINE -c "\COPY ( 
        SELECT * FROM qaqc_historic
      ) TO STDOUT DELIMITER ',' CSV HEADER;" > qaqc_historic.csv
    pg_dump -d $BUILD_ENGINE -t qaqc_historic -f qaqc_historic.sql  
)