#!/bin/bash

b=/usr/local/bin/masterha_check_status

## Get prompt variables
usage() { echo "Usage: $0 [-h host] [-c conf_file] [-b masterha_check_status binary]" 1>&2; exit 1; }

while getopts ":h:c:b:" o; do
    case "${o}" in
        h)
            h=${OPTARG}
            ;;
        c)
            c=${OPTARG}
            ;;
        b)
            b=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

check=`${b} --conf=${c}`
stat=$?

if [ $stat == '0'  ]; then
  echo "OK: $check"
  exit $stat

elif [ $stat == 2  ]; then
  echo "ERROR: $check"
  exit $stat

else
  echo "UNKNOWN: $check"
  exit $stat

fi
