#!/bin/sh
# Author: Narcís Pillao npillao@palominodb.com
# Description: Script to create snapshots of all volumes attached on EC2 server

# Constants
ec2_bin="/usr/local/ec2-api-tools-1.6.9.0/bin"
my_cert="/home/backup/backup_certificate.pem"
my_key="/home/backup/backup_key.pem"
instance_id=`wget -q -O- http://169.254.169.254/latest/meta-data/instance-id`
export JAVA_HOME=/usr

## Get prompt variables
usage() { echo "Usage: $0 [-r retention] [-d days]" 1>&2; exit 1; }

while getopts ":r:d:" o; do
    case "${o}" in
        r)
            r=${OPTARG}
            ;;
        d)
            d=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

RETENTION=${r}
datecheck_d=`date +%Y%m%d --date "${d} days ago"`

# Get all volume info and copy to temp file
$ec2_bin/ec2-describe-volumes -C $my_cert -K $my_key  --filter "attachment.instance-id=$instance_id" > /tmp/volume_info.txt 2>&1

# Creating snapshots
for volume in $(cat /tmp/volume_info.txt | grep "VOLUME" | awk '{print $2}')
do
    description="`hostname`_${instance_id}_backup-`date +%Y-%m-%d`"
    echo "Creating Snapshot for the volume: $volume with description: $description"
    $ec2_bin/ec2-create-snapshot -C $my_cert -K $my_key -d $description $volume
done

#if [[ `cat /tmp/snap_info.txt | awk '{print $4}'` != 'completed' ]]; then
#  echo "this is the body" | mail -s "Some problem found " "to@address"

# Get all snapshot info
$ec2_bin/ec2-describe-snapshots -C $my_cert -K $my_key | grep "$instance_id" > /tmp/snap_info.txt 2>&1

# Delete old snapshots
cat /tmp/snap_info.txt |while read line; do

    snapshot_name=`echo  $line | awk '{print $2}'`
    volume_name=`echo  $line | awk '{print $3}'`
    snapshot_date=`echo $line | awk '{print $5}' | awk -F "T" '{gsub ( "-","" ) ; print $1 }'`

    snapshot_ret=`grep $volume_name /tmp/snap_info.txt| wc -l`

    if [[ ${snapshot_date} < ${datecheck_d} ]] && [[ ${snapshot_ret} -ge ${RETENTION} ]]; then
        echo "deleting snapshot $snapshot_name created ${snapshot_date}"
        $ec2_bin/ec2-delete-snapshot -C $my_cert -K $my_key $snapshot_name
    fi

done
