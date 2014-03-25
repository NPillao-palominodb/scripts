#!/bin/bash
# ##############################################
# Author: Narcis Pillao - npillao@blackbirdit.com
# Description: This script will converts ALL databases from MyISAM to InnoDB. This script
#              uses percona-toolkit to avoid to lock tables. Tables which have not a PK
#              or several PKs cannot be converted, at the end the script will generate a file
#              to let you know which tables have not converted if any.
# Dependencies:
#    percona-toolkit-2.2.7-1.noarch
#    perl-TermReadKey-2.30-13.el6.x86_64  
################################################

####### FUNCTIONS #########

function approve {
  read APPROVE
  while [[ ${APPROVE} != 'Y' ]]; do
    if [[ ${APPROVE} == 'N' ]]; then
       echo "Process cancelled by user"
       exit 1
     fi	
     echo "Please type Y or N"
     read APPROVE
  done
}

usage() { echo "Usage: $0 [-b to keep old databases]" 1>&2; exit 1; }

######## MAIN #########

# Blocking ctrl + c
#trap control_c SIGINT

USER='root'
PASSW=''
ERRORS=()
SKIPPED_TBL=()
KEEP_OLD_DB=''


while getopts ":b:" o; do
    case "${o}" in
        b)
            KEEP_OLD_DB="--no-drop-old-table"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


TMP_FILE=`mktemp  /tmp/.databases.XXXXX`  || { echo "There is a problem creating tmp file"; exit 1; }

mysql -N -B -e "SELECT table_schema, table_name FROM INFORMATION_SCHEMA.TABLES   WHERE engine = 'MyISAM' AND table_schema not in ('mysql', 'information_schema');" |awk '{print $1"."$2}' > ${TMP_FILE}

echo ""
echo "===== DATABASES TO CONVERT ======"
cat ${TMP_FILE}
echo "================================="
echo ""

echo "You are going to alter these databases, do you agree? 'Y|N'"
approve
NPK=''
FULLTEXT=''

for LINE in `cat ${TMP_FILE}`; do

      DB=` echo ${LINE} | awk -F '.' '{print $1}'`
      TABLE=` echo ${LINE} | awk -F '.' '{print $2}'`

      echo " =============== Scanning ${TABLE} ==============="    
      NPK=`echo "select constraint_name from information_schema.table_constraints where table_name = '${TABLE}' and table_schema = '${DB}' and ( constraint_TYPE='PRIMARY KEY' or constraint_TYPE='UNIQUE') limit 1;" | mysql -B`

      if [[ -z ${NPK} ]]; then
        echo " ================ Skipping: This ${LINE} has not PK ============" |tee -a db_skipped.txt
        SKIPPED_TBL+=("${LINE}")

      else
	# Produces the drop statement if any fulltext indexes exist on this table
	echo " =============== Scanning ${LINE} for full text indexes ==============="
        FULLTEXT=`echo "select concat('drop index ',index_name,' on ',table_name,';') from information_schema.statistics where table_name = '${TABLE}' and table_schema = '${DB}' and index_type = 'FULLTEXT' ;" | mysql -B --skip-column-names`

	if [[ -n ${FULLTEXT} ]]; then
	  echo "Dropping any fulltext indexes"
	  echo "SQL: ${FULLTEXT}"
	  echo $FULLTEXT | mysql -v -v -v -B --skip-column-names $DB # Want this drop to be verbose and specific DB
	  if [ $? -ne 0 ]; then
        	ERRORS+=("${LINE}")
        	echo "ERROR: There was a problem dropping the full text index on ${LINE} Please review" |tee -a db_errors.txt
        	echo "       Do you want to continue with InnoDB conversion? Y|N "
        	approve
      	  else
        	echo "==============  ${LINE} fulltext index dropped  ==============="
     	  fi
  
	fi

        echo "converting ${LINE}"
        pt-online-schema-change  --execute ${KEEP_OLD_DB} --nocheck-replication-filters --chunk-time=0.5 --chunk-size-limit=0 --max-load=Threads_running=20 --no-check-plan --critical-load=Threads_running=100 --alter 'ENGINE=InnoDB' h=localhost,D=${DB},t=${TABLE}
  
        # Notify we found an error and store error found
        if [ $? -ne 0 ]; then
          ERRORS+=("${LINE}")
          echo "ERROR: There was a problem converting ${LINE} Please review" |tee -a db_errors.txt
          echo "       Do you want to continue with InnoDB conversion? Y|N "
          approve
        else
          echo "==============  ${LINE} converted  ===============" |tee -a tables_converted.txt
        fi
      fi
     
done

# Report a list with Tables not converted because did not have PK
if [[ ${#SKIPPED_TBL[@]} > 0  ]]; then
  echo "List of tables which has not been converted because did not have PK (${#SKIPPED_TBL[@]}):"
  echo "============================================================================"
  for i in "${SKIPPED_TBL[@]}"; do echo "$i" |tee -a no_PK_dbs.txt; done
else
  echo "Excellent! All tables had a PK !"
fi


# Report a list with ERRORS found
if [[ ${#ERRORS[@]} > 0  ]]; then
  echo "List of ERRORS found (${#ERRORS[@]}): "
  echo "==========================="
  for i in "${ERRORS[@]}"; do echo "$i"|tee -a error_dbs.txt; done
else
  echo "Excellent! Conversion process executed without issues !"
fi

# Removing temp file with databases to be converted
rm -f ${TMP_FILE}
