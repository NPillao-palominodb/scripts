#!/bin/bash
# Description: Sent a file via parameter with this formar DB.TABLE and this script
#              will convert all specified tables to InnoDB.


####### FUNCTIONS #########

function aproove {
  read APROOVE
  while [[ ${APROOVE} != 'Y' ]]; do
    if [[ ${APROOVE} == 'N' ]]; then
       echo "Process cancelled by user"
       exit 1
     fi	
     echo "Please type Y or N"
     read APROOVE
  done
}

## Get prompt variables
usage() { echo "Usage: $0 [-f db.table file]" 1>&2; exit 1; }


####### MAIN ########

while getopts ":f:" o; do
    case "${o}" in
        f)
            FILE_SRC=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[ -z ${FILE_SRC} ] && { echo "Error: You have to pass a file with db.table format (one line for table)"; exit 1; }
[ ! -f ${FILE_SRC} ] && { echo "Error: This file does not exist"; exit 1; }


echo ""
echo "===== DATABASES TO CONVERT ======"
cat ${FILE_SRC}
echo "================================="
echo ""
echo "You are going to alter these databases, do you agree? 'Y|N'"
aproove


for table in `cat ${FILE_SRC}`; do
     echo "Converting ${table}"
     mysql -N -B -e "ALTER TABLE ${table} ENGINE = InnoDB;"
     if [ $? -ne 0 ]; then
        ERRORS+=("${DB}.${TABLE}")
        echo "ERROR: There was a problem converting ${DB}.${TABLE} Please review"
        echo "       Do you want to continue with InnoDB conversion? Y|N "
        aproove   
     fi

done
