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

case $1 in
    dataloading | build | export | archive ) $1 ;;
    *) echo "$1 not found";;
esac
