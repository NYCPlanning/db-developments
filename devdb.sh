#!/bin/bash
source bash/config.sh

function dataloading { 
    shift;
    MODE="${1:-edm}"
    echo "mode: $MODE"
    ./bash/01_dataloading.sh $1
}

function build { 
    ./bash/02_build_devdb.sh 
}

function export { 
    ./bash/03_export.sh 
}

function archive { 
    ./bash/04_archive.sh 
}

function output {
    shift;
    name=$1
    format=$2
    case $format in 
        csv) CSV_export $1;;
        shp) SHP_export $1;;
        *) echo "format: $2 is unknow"
    esac
}

function library_archive {
    shift;
    get_version $2
    docker run --rm\
        -e AWS_S3_ENDPOINT=$AWS_S3_ENDPOINT\
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\
        -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY\
        -e AWS_S3_BUCKET=$AWS_S3_BUCKET\
        -v $(pwd)/templates/$1.yml:/library/$1.yml\
        -v $(pwd)/$1.csv:/library/$1.csv\
        -v $(pwd)/.library:/library/.library\
    nycplanning/library:ubuntu-latest bash -c "
        library archive -f $1.yml -s -l -o csv -v $version &
        library archive -f $1.yml -s -l -o pgdump -v $version &
        wait
    "
}

function library_archive_version {
    shift; 
    local name=$1
    local version=$2
    docker run --rm\
        -e AWS_S3_ENDPOINT=$AWS_S3_ENDPOINT\
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\
        -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY\
        -e AWS_S3_BUCKET=$AWS_S3_BUCKET\
        -v $(pwd)/templates/$name.yml:/library/$name.yml\
        -v $(pwd)/$name.csv:/library/$name.csv\
        -v $(pwd)/.library:/library/.library\
    nycplanning/library:ubuntu-latest bash -c "
        library archive -f $name.yml -s -l -o csv -v $version &
        library archive -f $name.yml -s -l -o pgdump -v $version &
        wait
    "
}

function import {
    shift;
    local name=$1
    local version=${2:-latest}
    import_public $1 $2
}

function sql {
    shift;
    psql $BUILD_ENGINE $@
}

function upload_to_bq {
    FILEPATH=dcp_developments/$VERSION/dcp_developments.csv
    curl -O https://nyc3.digitaloceanspaces.com/edm-recipes/datasets/$FILEPATH
    gsutil cp dcp_developments.csv gs://edm-temporary/$FILEPATH
    rm dcp_developments.csv
    location=US
    dataset=dcp_developments
    tablename=$dataset.$(tr [A-Z] [a-z] <<< "$VERSION")
    bq show $dataset || bq mk --location=$location --dataset $dataset
    bq show $tablename || bq mk $tablename
    bq load \
        --location=$location\
        --source_format=CSV\
        --quote '"' \
        --skip_leading_rows 1\
        --replace\
        --allow_quoted_newlines\
        $tablename \
        gs://edm-temporary/$FILEPATH \
        schemas/dcp_developments.json
}

case $1 in
    dataloading | build | export | archive ) $1 $@ ;;
    geocode) geocode ;;
    import) import $@ ;;
    output) output $@ ;;
    sql) sql $@ ;;
    bq) upload_to_bq ;;
    library_archive) library_archive $@ ;;
    library_archive_version) library_archive_version $@ ;;
    *) echo "$1 not found" ;;
esac
