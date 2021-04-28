#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source $CURRENT_DIR/config.sh

display "archive DevDB"
archive EXPORT_devdb developments

display "archive HousingDB"
archive EXPORT_housing dcp_housing

# archive yearly_unitchange table
# archive yearly_unitchange yearly_unitchange