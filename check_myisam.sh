#!/bin/bash
# ##############################################
# Author: Narcis Pillao - npillao@blackbirdit.com
# Description: Check whether there is a MyISAM table present
# Dependencies:
################################################


TMP_FILE=`mktemp  /tmp/.databases.XXXXX`  || { echo "There is a problem creating tmp file"; exit 1; }

mysql -B -N -e "show databases" |egrep -iv 'Database|mysql|information_schema|performance_schema' > ${TMP_FILE}

for DB in `cat ${TMP_FILE}`; do

  echo "show table status" | mysql --batch --skip-column-names $DB |while read line; do
      echo $DB: $line |grep -i myisam |awk '{print $1 $2}'
   done

done

rm -f ${TMP_FILE}
