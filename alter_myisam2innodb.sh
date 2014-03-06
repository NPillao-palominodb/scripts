#!/bin/bash
# Description: Create a file (dball) with all databases you want to convert from MyISAM to InnoDB

for db in `cat dball`; do

  for tbl in `echo "show tables" | mysql --batch --skip-column-names $db`; do
     echo "converting ${db}.${tbl}"
     mysql $db -e "ALTER TABLE \`$tbl\` ENGINE = InnoDB;"; done

done
