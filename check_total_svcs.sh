#!/bin/bash

# checks the total amount of service checks within opsview + timeseries graphing data

usage() {
  echo "Usage: $0 [-h]"
  echo "A service check count within opsview monitor with timeseries graphing data, the script needs the username and password within the script respectively"
}

while getopts ":h" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      usage
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." 1>&2
      usage
      exit 1
      ;;
  esac
done

# Return Codes
OK=0

## Set the Opsview API username and password ##
API_USERNAME="admin"
API_PASSWORD="initial"

# Opsview Diag Data 
CURRENT_CHECKS=$(/opt/opsview/coreutils/bin/opsview_diag | grep -w 'Total Services'| sed 's/[^0-9]*//g' | awk '{print $1}')

echo "OK - $CURRENT_CHECKS Checks in Total | services=$CURRENT_CHECKS;;"
exit 0
