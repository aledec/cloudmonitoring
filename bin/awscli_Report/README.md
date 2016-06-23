awscli_Report
====
Provide a report on specify list of time with all the information for the following types of aws services.

- List of total of instances, with respective ami, type of instnaces, ip, key, and all the critical information.
- List of total of snapshots, which each account related.
- List of total of volumes, with each instance associate and device id
- List of total images, usefull to get control on based ami in use and present on each account.
- List of total users on each aws account. Need to be improvement with policy capacity.
- List of total S3 bucket, and path for each.
- List for total of Redshift clusters


## Installation
- Copy global contents of "etc" and "logs" folder into username who is going to execute this, on folder "$HOME/scripts"
- Copy folder "bin/awscli_InstanceStatus" into "$HOME/scripts/bin"
- Change variables for configuration folder "tc" if required
- Test execution using the following command to work with all the accounts
```
./global_check_awscli_global_report.sh
```
- Test execution using the following command to work only with specific accounts
```
./check_awscli_global_report.sh
```

## Crontab Example line
Crontab example
```
#AWS CLI Weekly report                                                                                                 
00 9 * * 1 cd /home/ec2-user/scripts/bin/awscli_Report; ./global_check_awscli_global_report.sh
```
