#!/bin/bash
# Script to get all error log files for each RDS instance
# Dependency: To have configured AWS keys

for ins in `rds-describe-db-instances | grep DBINSTANCE |awk '{print $2}'`; do

  echo "== Scanning logs for: ${ins} RDS instance ... =="
  FILE=`rds-describe-db-log-files ${ins} |grep -i error| awk '{print $2}'`
  if [[ ! -z ${FILE} ]]; then
    echo "$FILE" |sort -k3 -t . -n | while read line; do
      echo $line
      rds-download-db-logfile ${ins} --log-file-name ${line}
    done
  fi

done
