#!/bin/bash
# Description: Check all tables listed on dball file are MyISAM tables

for i in `cat dball`; do

  echo "show table status" | mysql --batch --skip-column-names $i |while read line; do
      echo $i: $line |grep -i myisam |awk '{print $1 $2}'
   done

done
