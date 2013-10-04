#!/bin/bash
# ====================================================================================
# Author: Narcis Pillao - npillao@palominodb.com
# License: GPL License (see COPYING)
# Copyright 2013 PalominoDB Inc.
# Description: This script gathers all slow logs stored on your associated RDS account
# Requirement: You must download RDS CLI tool and set your credentials.
#              http://s3.amazonaws.com/rds-downloads/RDSCli.zip
# ====================================================================================

#Create daily directory
DATE=`date +%F`
mkdir ${DATE}


for ins in `rds-describe-db-instances | grep DBINSTANCE |awk '{print $2}'`; do

  FILE=`rds-describe-db-log-files ${ins} |grep -i slow| awk '{print $2}'`
  if [[ ! -z ${FILE} ]]; then
    mkdir ${DATE}/${ins}
    echo "$FILE" |sort -k3 -t . -n | while read line; do
      FILENAME=`basename ${line}`
      # Store slow logs separated by RD instance
      rds-download-db-logfile ${ins} --log-file-name ${line} > ${DATE}/${ins}/${FILENAME}
    done
  fi

done
