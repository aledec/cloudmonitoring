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
CLIENTSCHECK="./check_awscli_specific_status_report.sh"
TMPDIR=~/scripts/logs/awscli_InstanceStatus
CSV_ec2_status_total=$TMPDIR/list_out_total_ec2_status_$DATEFILE.csv
REPORTCONTENT=$TMPDIR/report_$DATEFILE.txt

echo "Account Name,Instance ID,Instance Status,System Status,Impaires Since,Events,Description,NotBefore" > $CSV_ec2_status_total

 while read line; do
  ACCOUNTAWS=$(echo $line | awk '{print $1}')
  ACCOUNTNAME=$(echo $line | awk '{print $2}')
  echo "Doing: $ACCOUNTAWS"
  $CLIENTSCHECK $ACCOUNTAWS $ACCOUNTNAME $DATEFILE
 done < $PROFILES

function sendemail(){
 $SENDEMAIL -f $FROMADDRESS -t $TOADDRESS -u "Instance status report for AWS Accounts at $DATEFILE" -o message-file=$REPORTCONTENT -a $CSV_ec2_status_total
}

function detailed(){
 echo -e "#######################################" > $REPORTCONTENT
 echo -e "# Resume for All clients on AWS on $DATEFILE" >> $REPORTCONTENT
 echo -e "Instances on healthy State:     " $(egrep -v "failed|insufficient-data|impaired|instance-stop" $CSV_ec2_status_total | wc -l) >> $REPORTCONTENT
 echo "Instances Sceduled for retirement: " $(grep "instance-retirement" $CSV_ec2_status_total | wc -l) >> $REPORTCONTENT
 echo "Instances with status failed:      " $(egrep "failed|insufficient-data|impaired|instance-stop" $CSV_ec2_status_total | wc -l) >> $REPORTCONTENT
 echo -e "#######################################" >> $REPORTCONTENT
 echo "
# Instances status checks fail due to following reasons:
* Loss of network connectivity
* Loss of system power
* Software issues on the physical host
* Hardware issues on the physical host 
* Incorrect networking or startup configuration
* Exhausted memory
* Corrupted file system
* Incompatible kernel" >> $REPORTCONTENT
}

if [ $(cat $CSV_ec2_status_total | egrep "failed|insufficient-data|impaired|instance-stop|instance-retirement" | wc -l) -ge 1 ]; then
 echo "# Found instances not healthy, reporting via email..."
 detailed
 sendemail
fi

