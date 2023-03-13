#!/bin/bash

# check the hosts limit within opsview monitor with timeseries graphing data

usage() {
  echo "Usage: $0 [-h]"
  echo "A hosts check within opsview monitor with timeseries graphing data, the script needs the username and password within the script respectively"
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
WARNING=1
CRITICAL=2
UNKNOWN=3

## Set the Opsview API username and password ##
API_USERNAME="admin"
API_PASSWORD="initial"

# Opsview REST API Call 
HOSTS_LIMIT=$(/opt/opsview/coreutils/bin/opsview_rest --username=$API_USERNAME --password=$API_PASSWORD --pretty GET info | grep hosts_limit | sed 's/[^0-9]*//g' | awk '{print $1}')

# Opsview Diag Data 
CURRENT_HOSTS=$(/opt/opsview/coreutils/bin/opsview_diag | grep -w 'Total Hosts'| sed 's/[^0-9]*//g' | awk '{print $1}')

# Calculates the 70% Threshold
threshold=$(echo "$HOSTS_LIMIT * 0.7" | bc)

# Convert $CURRENT_HOSTS to a float before comparison
if (( $(echo "$CURRENT_HOSTS >= $threshold" | bc -l) )); then
    echo "WARNING - $CURRENT_HOSTS/$HOSTS_LIMIT - More than 70% of the Hosts Limit Reached"
    exit 1
elif [[ "$CURRENT_HOSTS" -ge "$HOSTS_LIMIT" ]]; then
    echo "CRITICAL - $CURRENT_HOSTS/$HOSTS_LIMIT - Number of hosts is greater than hosts limit"
    exit 2
else
    echo "OK - $CURRENT_HOSTS/$HOSTS_LIMIT - Less than 70% of Current Host Limit"
    exit 0
fi
