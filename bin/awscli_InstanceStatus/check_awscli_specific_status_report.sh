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
OUTDIR="out"
TMPDIR=~/scripts/logs/awscli_InstanceStatus
OUT_ec2_status=$TMPDIR/list_ec2_status_$ACCOUNTAWS.txt
CSV_ec2_status=$TMPDIR/list_ec2_status_$ACCOUNTAWS.csv
CSV_ec2_status_total=$TMPDIR/list_out_total_ec2_status_$DATEFILE.csv

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
function list_ec2_instancestatus(){
    $AWS_BIN_PATH --profile $ACCOUNTAWS ec2 describe-instance-status --query 'InstanceStatuses[*].[InstanceId,InstanceStatus.Status,SystemStatus.Status,SystemStatus.Details.ImpairedSince,Events.Code,Events.Description,Events.NotBefore]' --output text > $OUT_ec2_status
    RETURN=$?
     #Add profilename at begining of output in order to easily track each client in global report
     sed -i "s/^/$ACCOUNTNAME,/g" $OUT_ec2_status
     #Replace whitespaces on some volumes
     sed -i "s/ /_/g" $OUT_ec2_status
    check_return $RETURN
}

function globalreport(){
echo $ACCOUNTNAME","$(egrep -c 'running|stopped' $OUT_list_instances_ec2)","$(grep -c running $OUT_list_instances_ec2)","$(grep -c stopped $OUT_list_instances_ec2)","$(wc -l $OUT_list_volumes_ec2 | awk '{print $1}')","$(grep -c in-use $OUT_list_volumes_ec2)","$(grep -c available $OUT_list_volumes_ec2)","$(awk '{s+=$5} END {print s}' $OUT_list_volumes_ec2)","$(wc -l $OUT_list_snapshots_ec2 | awk '{print $1}')","$(awk '{s+=$4} END {print     s}' $OUT_list_snapshots_ec2) >> $OUT_total_ec2
}

function generatecsv(){
 echo "Account Name,Instance ID,Instance Status,System Status,Impaired Since,Events,Description,NotBefore" > $CSV_ec2_status
  sed 's/\t/,/g' $OUT_ec2_status >> $CSV_ec2_status
  sed 's/\t/,/g' $OUT_ec2_status >> $CSV_ec2_status_total
}

function sendemail(){
 $SENDEMAIL -f $FROMADDRESS -t $TOADDRESS -u "Instance status report for $ACCOUNTAWS - $ACCOUNTNAME at $DATE" -m "Attached temporary list" -a $CSV_ec2_status
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
	list_ec2_instancestatus
	#detailed
	#globalreport
	generatecsv
#	sendemail
fi
