#!/bin/bash

########################################################
# EMAIL SETTINGS
########################################################
source ~/scripts/etc/sendemail.config

########################################################
## VARIABLES - NOT CHANGE
########################################################
DATEFILE=$(date +%Y%m%d%H%M)
if [ ! -z $1 ]; then
  if [ $# -lt 2 ]; then
    echo "Some parameter introduce, remember that to manually run you need to invoque as following"
    echo $0 [list_of_profiles] [toaddress]
  else
  ##Use default list of hosts
  PROFILES=$1
  TOADDRESS=$2
  fi
else
  ##Using default list of profiles
  PROFILES=~/scripts/etc/aws-client-profiles.txt
fi
CLIENTSCHECK="./check_awscli_global_report.sh"
TMPDIR="$HOME/scripts/logs/awscli_Report"
OUTDIR="$HOME/scripts/logs/awscli_Report"
OUT_total_ec2=$OUTDIR/list_out_total_ec2_$DATEFILE.csv
OUT_total_images_ec2=$OUTDIR/total_images_ec2_$DATEFILE.csv
TMP_filter_images_ec2=$TMPDIR/total_images_ec2_$DATEFILE.tmp
CSV_total_instances_ec2=$OUTDIR/total_instances_ec2_$DATEFILE.csv
CSV_total_snapshots_ec2=$OUTDIR/total_snapshots_ec2_$DATEFILE.csv
CSV_total_volumes_ec2=$OUTDIR/total_volumes_ec2_$DATEFILE.csv
CSV_total_images_ec2=$OUTDIR/total_images_ec2_$DATEFILE.csv
CSV_total_users_iam=$OUTDIR/total_users_iam_$DATEFILE.csv
CSV_total_buckets_s3api=$OUTDIR/total_buckets_s3api_$DATEFILE.csv
CSV_total_clusters_redshift=$TMPDIR/total_clusters_redshift_$DATEFILE.csv

echo "Account Name,Assigned Path,Attached Date,Volume ID,Instance ID,Size,Status" > $CSV_total_volumes_ec2
echo "Account Name,Snapshot ID,Volume ID,Created Date,VolumeSize,OwnerAlias" > $CSV_total_snapshots_ec2
echo "Account Name,Instance Name,Zone,Launch Date,Status,Last Status Code,Instance ID,Ami Based ID,Private IP,Public IP,Instance Type,Platform(OS),Key Name" > $CSV_total_instances_ec2
echo "Account Name,AMI Based ID, AMI Description" > $CSV_total_images_ec2
echo "Account Name,Instances,Instances Started,Instances Stopped,Volumes,Volumes In Use,Volumes Not in Use,Storage Assigned,Total Snapshots,Size Snapshot(GB)" > $OUT_total_ec2
echo "Account Name,UserName,Creation Date, Last Password Used Date" > $CSV_total_users_iam
echo "Account Name,Bucket Name, Bucket Creation Date" > $CSV_total_buckets_s3api
echo "Account Name,DBName,ClusterIdentifier,AvailabilityZone,NodeType,Encrypted,Address,Port" > $CSV_total_clusters_redshift
 while read line; do
  ACCOUNTAWS=$(echo $line | awk '{print $1}')
  ACCOUNTNAME=$(echo $line | awk '{print $2}')
  echo "Doing: $ACCOUNTAWS"
  $CLIENTSCHECK $ACCOUNTAWS $ACCOUNTNAME $DATEFILE
 done < $PROFILES

function preparefilterimagelist(){
 #echo "AMI Based ID, AMI Description" > $CSV_filter_images_ec2
 cat $OUT_total_images_ec2 | awk -F"," '{print $2 " " $3}' | sort | uniq >> $TMP_filter_images_ec2

}

function sendemail(){
 $SENDEMAIL -f $FROMADDRESS -t $TOADDRESS -u "Weekly report for all hosts at $DATEFILE" -m "Weekly Report For all AWS Configured Platform" -a $OUT_total_ec2 -a $CSV_total_instances_ec2 -a $CSV_total_snapshots_ec2 -a $CSV_total_volumes_ec2 -a $CSV_total_images_ec2 -a $CSV_total_users_iam -a $CSV_total_buckets_s3api -a $CSV_total_clusters_redshift
}

sendemail
preparefilterimagelist
