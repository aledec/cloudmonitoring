#!/bin/bash

########################################################
## VARIABLES - CHANGE
########################################################
ACCOUNTAWS=$1
ACCOUNTNAME=$2
DATEFILE=$3
AWS_BIN_PATH=/usr/bin/aws

########################################################
# EMAIL SETTINGS
########################################################
source ~/scripts/etc/sendemail.config

########################################################
## VARIABLES - NOT CHANGE
########################################################
DATE=$(date +%Y%m%d%H%M)
TMPDIR="$HOME/scripts/logs/awscli_Report"
OUTDIR="$HOME/scripts/logs/awscli_Report"
OUT_list_volumes_ec2=$TMPDIR/list_volumes_ec2_$ACCOUNTAWE.txt
OUT_list_snapshots_ec2=$TMPDIR/list_snapshots_ec2_$ACCOUNTAWS.txt
OUT_list_instances_ec2=$TMPDIR/list_instances_ec2_$ACCOUNTAWS.txt
OUT_list_images_ec2=$TMPDIR/list_images_ec2_$ACCOUNTAWS.txt
OUT_list_users_iam=$TMPDIR/list_users_iam_$ACCOUNTAWS.txt
OUT_list_buckets_s3api=$TMPDIR/list_buckets_s3api_$ACCOUNTAWS.txt
OUT_list_clusters_redshift=$TMPDIR/list_clusters_redshift_$ACCOUNTAWS.txt
CSV_list_volumes_ec2=$OUTDIR/list_volumes_ec2_$ACCOUNTAWS.csv
CSV_list_snapshots_ec2=$OUTDIR/list_snapshots_ec2_$ACCOUNTAWS.csv
CSV_list_instances_ec2=$OUTDIR/list_instances_ec2_$ACCOUNTAWS.csv
CSV_list_images_ec2=$OUTDIR/list_images_ec2_$ACCOUNTAWS.csv
CSV_list_users_iam=$OUTDIR/list_users_iam_$ACCOUNTAWS.csv
CSV_list_buckets_s3api=$OUTDIR/list_buckets_s3api_$ACCOUNTAWS.csv
CSV_list_clusters_redshift=$TMPDIR/list_clusters_redshift_$ACCOUNTAWS.csv
CSV_total_instances_ec2=$OUTDIR/total_instances_ec2_$DATEFILE.csv
CSV_total_snapshots_ec2=$OUTDIR/total_snapshots_ec2_$DATEFILE.csv
CSV_total_volumes_ec2=$OUTDIR/total_volumes_ec2_$DATEFILE.csv
CSV_total_images_ec2=$OUTDIR/total_images_ec2_$DATEFILE.csv
CSV_total_users_iam=$OUTDIR/total_users_iam_$DATEFILE.csv
CSV_total_buckets_s3api=$OUTDIR/total_buckets_s3api_$DATEFILE.csv
CSV_total_clusters_redshift=$TMPDIR/total_clusters_redshift_$DATEFILE.csv
OUT_total_ec2=$OUTDIR/list_out_total_ec2_$DATEFILE.csv

########################################################
# Report files - NOT CHANGE
########################################################
REPORTSTATUS=$TMPDIR/status_$ACCOUNTAWS.txt
echo "" > $REPORTSTATUS
REPORTCONTENT=$TMPDIR/report_$ACCOUNTAWS.txt

########################################################
## FUNCTIONS
########################################################

#Date stamp calculator for UTC
date2stamp () {
    date --utc --date "$1" +%s
}
#Date diff calculator
dateDiff (){
    case $1 in
	-s)   sec=1;      shift;;
	-m)   sec=60;     shift;;
	-h)   sec=3600;   shift;;
	-d)   sec=86400;  shift;;
	*)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}


#Check correct run of script
check_return()
if [ $1 -ne 0 ]; then
    $SENDEMAIL -f $FROMADDRESS -t $TOADDRESS -u "Weekly report ERROR for $ACCOUNTAWS - $ACCOUNTNAME AT $DATE" -m "Error during execution. 
    Error may be related to one of the following.
    * Insuficient privileges for User
    * Account decommissioned
    * User not exist/Access Key invalid
    * Component without name/special chars on their name no longer supported
    * Other error not yet reported
    
    In order to proper debug the error try each check commands manually"
    echo "Error in $ACCOUNTAWS - $ACCOUNTNAME"
fi

#List Volumes available
function list_volumes_ec2(){
	$AWS_BIN_PATH ec2 describe-volumes --profile $ACCOUNTAWS --query 'Volumes[*].{ID:VolumeId,InstanceId:Attachments[0].InstanceId, AttachTime:Attachments[0].Device,Size:Size,State:State,CreateTime:CreateTime}' --output text > $OUT_list_volumes_ec2
    RETURN=$?
     #Add profilename at begining of output in order to easily track each client in global report
     sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_volumes_ec2
     #Replace whitespaces on some volumes
     sed -i "s/ /_/g" $OUT_list_volumes_ec2
    check_return $RETURN
}

#List Snapshots owned by account only
function list_snapshots_ec2(){
    $AWS_BIN_PATH ec2 --profile $ACCOUNTAWS describe-snapshots --query Snapshots[*].[SnapshotId,VolumeId,StartTime,VolumeSize,OwnerAlias] --owner self --output text | sort -r -k 3,4 > $OUT_list_snapshots_ec2
    RETURN=$?
     #Add profilename at begining of output in order to easily track each client in global report
     sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_snapshots_ec2
     #Replace whitespaces on some snapshots
     sed -i "s/ /_/g" $OUT_list_snapshots_ec2
    check_return $RETURN
}

#List Instances EC2
function list_instances_ec2(){
 $AWS_BIN_PATH ec2 --profile $ACCOUNTAWS describe-instances --query 'Reservations[*].Instances[*].[join(`,`,Tags[?Key==`Name`].Value), Placement.AvailabilityZone, LaunchTime, State.Name, StateReason.Code, InstanceId, ImageId, PrivateIpAddress, PublicIpAddress, InstanceType, Platform, KeyName]' --output text> $OUT_list_instances_ec2
  RETURN=$?
   #Add profilename at begining of output in order to easily track each client in global report
   sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_instances_ec2
   #Replace whitespaces on some ami
   sed -i "s/ /_/g" $OUT_list_instances_ec2
  check_return $RETURN
}

function list_images_ec2(){
 AMIS="$(cat $OUT_list_instances_ec2 | awk '{print $7}'|sort|uniq)"
 $AWS_BIN_PATH ec2 --profile $ACCOUNTAWS describe-images --image-ids $AMIS --query 'Images[*].[ImageId, Name]' --output text > $OUT_list_images_ec2
  RETURN=$?
   #Add profilename at begining of output in order to easily track each client in global report
   sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_images_ec2
   #Replace whitespaces on some images
   sed -i "s/ /_/g" $OUT_list_images_ec2
  check_return $RETURN
}

function list_users_iam(){
  $AWS_BIN_PATH iam --profile $ACCOUNTAWS list-users --query 'Users[*].[UserName, CreateDate, PasswordLastUsed]' --output text > $OUT_list_users_iam
   RETURN=$?
    sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_users_iam
    check_return $RETURN
}

function list_budgets_s3api(){
  $AWS_BIN_PATH s3api --profile $ACCOUNTAWS list-buckets --query 'Buckets[*].[Name, CreationDate]' --output text > $OUT_list_buckets_s3api
   RETURN=$?
    sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_buckets_s3api
    check_return $RETURN
}

function list_clusters_redshift(){
  $AWS_BIN_PATH redshift --profile $ACCOUNTAWS describe-clusters --query Clusters[*].[DBName,ClusterIdentifier,AvailabilityZone,NodeType,Encrypted,Endpoint.Address,Endpoint.Port,KmsKeyId] > $OUT_list_clusters_redshift
  RETURN=$?
   sed -i "s/^/$ACCOUNTNAME,/g" $OUT_list_clusters_redshift
   check_return $RETURN
}

#Get diff between last retentions levels
function get_diff_last_retention(){
    VOLUMEID=$1
    LASTSNAPSHOT=$(grep $VOLUMEID $OUT_list_snapshots_ec2 | awk '{print $3}' | awk -F"T" '{print $1}' | sort -r | head -1)
    if [[ $LASTSNAPSHOT == "" ]]; then
	echo -e "BACKUPERROR: VolumeID $VOLUMEID has not backup configured" >> $REPORTSTATUS
    else
	DAYS=$(dateDiff -d $(date +%Y-%m-%d) $LASTSNAPSHOT)
	if [ $DAYS -ge 1 ]; then
	    echo -e "BACKUPERROR: VolumeID $VOLUMEID hasnt backup since $LASTSNAPSHOT - $DAYS days" >> $REPORTSTATUS
	fi
    fi
}

function list_volumes_for_check(){
    while read line; do
	VOLUME=$(echo $line | awk '{print $3}')
	get_diff_last_retention $VOLUME
    done < $OUT_list_volumes_ec2
}

function detailed(){
 echo -e "#######################################" > $REPORTCONTENT
 echo -e "Resume for client $ACCOUNTAWS - $ACCOUNTNAME on $DATE" >> $REPORTCONTENT
 echo -e "\nTotal volumes:                  " $(wc -l $OUT_list_volumes_ec2 | awk '{print $1}') >> $REPORTCONTENT
 echo "Total instances:                   " $(egrep -c 'running|stopped' $OUT_list_instances_ec2) >> $REPORTCONTENT
 echo "Total Storage Assigned(GB):        " $(awk '{s+=$5} END {print s}' $OUT_list_volumes_ec2) >> $REPORTCONTENT
 echo "######" >> $REPORTCONTENT
 echo "Total volumes in use:              " $(grep -c in-use $OUT_list_volumes_ec2) >> $REPORTCONTENT
 echo "Total volumes not in use:          " $(grep -c available $OUT_list_volumes_ec2) >> $REPORTCONTENT
 echo "Total snapshots created:           " $(wc -l $OUT_list_snapshots_ec2 | awk '{print $1}') >> $REPORTCONTENT
 echo "Total instances running:           " $(grep -c running $OUT_list_instances_ec2) >> $REPORTCONTENT
 echo "Total instances stopped:           " $(grep -c stopped $OUT_list_instances_ec2) >> $REPORTCONTENT
 echo "Vols without snapshot backup/error:" $(grep -c BACKUPERROR $REPORTSTATUS) >> $REPORTCONTENT
 echo -e "\n#######################################" >> $REPORTCONTENT
cat $REPORTSTATUS >> $REPORTCONTENT
}

function globalreport(){
echo $ACCOUNTNAME","$(egrep -c 'running|stopped' $OUT_list_instances_ec2)","$(grep -c running $OUT_list_instances_ec2)","$(grep -c stopped $OUT_list_instances_ec2)","$(wc -l $OUT_list_volumes_ec2 | awk '{print $1}')","$(grep -c in-use $OUT_list_volumes_ec2)","$(grep -c available $OUT_list_volumes_ec2)","$(awk '{s+=$5} END {print s}' $OUT_list_volumes_ec2)","$(wc -l $OUT_list_snapshots_ec2 | awk '{print $1}')","$(awk '{s+=$4} END {print     s}' $OUT_list_snapshots_ec2) >> $OUT_total_ec2
}

function generatecsv(){
 echo "Account Name,Assigned Path,Attached Date,Volume ID,Instance ID,Size,Status" > $CSV_list_volumes_ec2
  sed 's/\t/,/g' $OUT_list_volumes_ec2 >> $CSV_list_volumes_ec2
  sed 's/\t/,/g' $OUT_list_volumes_ec2 >> $CSV_total_volumes_ec2
 echo "Account Name,Snapshot ID,Volume ID,Created Date,VolumeSize,OwnerAlias" > $CSV_list_snapshots_ec2
  sed 's/\t/,/g' $OUT_list_snapshots_ec2 >> $CSV_list_snapshots_ec2
  sed 's/\t/,/g' $OUT_list_snapshots_ec2 >> $CSV_total_snapshots_ec2
 echo "Account Name,Instance Name,Zone,Launch Date,Status,Last Status Code,Instance ID,Ami Based ID,Private IP,Public IP,Instance Type,Platform(OS),Key Name" > $CSV_list_instances_ec2
  sed 's/\t/,/g' $OUT_list_instances_ec2 >> $CSV_list_instances_ec2
  sed 's/\t/,/g' $OUT_list_instances_ec2 >> $CSV_total_instances_ec2
 echo "Account Name,AMI Based ID, AMI Description" > $CSV_list_images_ec2
  sed 's/\t/,/g' $OUT_list_images_ec2 >> $CSV_list_images_ec2
  sed 's/\t/,/g' $OUT_list_images_ec2 >> $CSV_total_images_ec2
 echo "Account Name,UserName,Creation Date, Last Password Used Date" > $CSV_list_users_iam
  sed 's/\t/,/g' $OUT_list_users_iam >> $CSV_list_users_iam
  sed 's/\t/,/g' $OUT_list_users_iam >> $CSV_total_users_iam
 echo "Account Name,S3 Bucket Name,Creation Date" > $CSV_list_buckets_s3api
  sed 's/\t/,/g' $OUT_list_buckets_s3api >> $CSV_list_buckets_s3api
  sed 's/\t/,/g' $OUT_list_buckets_s3api >> $CSV_total_buckets_s3api
 echo "Account Name,DBName,ClusterIdentifier,AvailabilityZone,NodeType,Encrypted,Address,Port" > $CSV_list_clusters_redshift
  sed 's/\t/,/g' $OUT_list_clusters_redshift >> $CSV_list_clusters_redshift
  sed 's/\t/,/g' $OUT_list_clusters_redshift >> $CSV_total_clusters_redshift
}

function sendemail(){
 $SENDEMAIL -f $FROMADDRESS -t $TOADDRESS -u "Weekly report for $ACCOUNTAWS - $ACCOUNTNAME at $DATE" -o message-file=$REPORTCONTENT -a $CSV_list_volumes_ec2 $CSV_list_snapshots_ec2 $CSV_list_instances_ec2 $CSV_list_users_iam $CSV_list_buckets_s3api $CSV_total_clusters_redshift
echo "Sent $ACCOUNTAWS - $ACCOUNTNAME"
}

# Help
function help()
{
	echo "Usage: $0 [EC2-Configured-profile]"
	echo "     $0 awsclientname clientname"
	echo " "
	echo " # Parameters"
	echo "      [EC2-Configured-profile]: Client Name configuration"
	echo "      [Client Name]: Client Name(without spaces)"
	exit 2
}

########################################################
## STARTUP
########################################################

if [ $# -lt 2 ]; then
	echo -en '\E[47;31m'"\033[1m ERROR - Check actual parameters \033[0m\n"
	help
else
	list_volumes_ec2
	list_snapshots_ec2
	list_instances_ec2
        list_images_ec2
	list_volumes_for_check
	list_users_iam
	list_budgets_s3api
	list_clusters_redshift
	detailed
	globalreport
	generatecsv
	sendemail
fi
