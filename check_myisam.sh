#!/bin/bash
# ##############################################
# Author: Narcis Pillao - npillao@blackbirdit.com
# Description: Check whether there is a MyISAM table present
# Dependencies:
################################################


mysql -e "SELECT table_schema, table_name, engine FROM INFORMATION_SCHEMA.TABLES   WHERE engine = 'MyISAM' AND table_schema not in ('mysql', 'information_schema');"



