#!/bin/bash
source bash/config.sh

function dataloading { 
    ./bash/01_dataloading.sh 
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

function import {
    shift;
    import_public $1 $2
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

case $1 in
    dataloading | build | export | archive ) $1 ;;
    geocode) geocode ;;
    import) import $@ ;;
    output) output $@ ;;
    library_archive) library_archive $@ ;;
    *) echo "$1 not found" ;;
esac
