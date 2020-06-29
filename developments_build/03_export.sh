#!/bin/bash
source config.sh

# Generate output tables
psql $BUILD_ENGINE\
    -v VERSION=$VERSION\ 
    -v CAPTURE_DATE=$CAPTURE_DATE\
    -f sql/export.sql