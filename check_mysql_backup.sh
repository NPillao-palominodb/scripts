#!/bin/bash
# Script to find out errors during backup proccess, it also detects whether the backup is still running
# It scans executed backups during current and past day
# Dependency: mysql-zrm


TODAY=`date '+%a %b %d'`
YESTERDAY=`date --date="yesterday" |awk '{print $1,$2,$3}'`
STATUS=0
COMMENT=""
# store running backups
COMMENTR=""
# store error backups
COMMENTE=""
DIRS=()
RUN=0

# Get all project names and store then whitin array
for proj  in $(mysql-zrm-reporter backup-performance-info --fields backup-set --noheader 2> /dev/null | sort | uniq ); do
  DIRS+=("${proj}")
done

if [ -z "$proj" ]; then
    echo "UNKNOWN - Not able to load any backup. May be a permission problem or zrm is missconfigured"
    exit 1
fi

# Looking for current and past dayly backups
for dir in "${DIRS[@]}"; do
    ROW=$(mysql-zrm-reporter backup-performance-info --fields backup-date,backup-level,backup-size,backup-status --noheader --where backup-set=${dir} 2> /dev/null |grep -E "${YESTERDAY}|${TODAY}"  |grep -vi succeeded )

  if [[ $ROW ]];then
      if [[ $ROW =~ '---' ]]; then
         COMMENTR+=`echo "$ROW" |awk '{print $1,$3,$4,$5}'`
         RUN=1
      else
        COMMENTE+=`echo "$ROW" |awk '{print $1,$3,$4,$5}'`
        STATUS=1
      fi
  fi
done

if [[ $STATUS -eq 1 ]]; then
  COMMENT="WARNING - Backup Failed: $COMMENTE"
elif [[ $RUN -eq 1 ]]; then
  COMMENT="WARNING - Backup still running for: $COMMENTR"
  STATUS=1
else
 COMMENT="OK - Backup finished succesfully"
fi

echo ${COMMENT}
exit ${STATUS}
