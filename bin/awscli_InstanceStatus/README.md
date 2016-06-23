awscli_InstanceStatus
====
Set of scripts to get based on a list of configured aws profile the instance list and status for all of them, and report via email
- Report on CSV instance status
- Report on CSV instances with any Failure on underlined hardware based on aws kind of failures

## Installation
- Copy global contents of "etc" and "logs" folder into username who is going to execute this, on folder "$HOME/scripts"
- Copy folder "bin/awscli_InstanceStatus" into "$HOME/scripts/bin"
- Change variables for configuration folder "tc" if required
- Test execution using the following command
```
./global_check_awscli_global_report.sh
```

## Crontab Example line
Crontab example
```
#Daily Report for instances failed and events for retirement on awscli
10 9 * * 1 cd /home/ec2-user/scripts/bin/awscli_InstanceStatus; ./global_check_awscli_global_report.sh
```

## Type of normal aws failures
- Loss of network connectivity
- Loss of system power
- Software issues on the physical host
- Hardware issues on the physical host 
- Incorrect networking or startup configuration
- Exhausted memory
- Corrupted file system
- Incompatible kernel

