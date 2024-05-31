# SQLRDS2014Upgrade
SQL RDS Upgrade from 2014 to higher version.

# What does the automation tool achieve?

When you perform a major version in-place upgrade by following [Major Version Upgrade](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.SQLServer.html) , you will also have to perform few additional manual steps like copying paramter group and option group. There is no AWS CLI command to perform this task in a automated way.

This automation tool helps you to carry out major version in-place upgrade, as a single-click deployment with few user inputs.


# High level Steps

- Check upgrade path
- Create new parameter group for target version
- Copy the parameters to target parameter group 
- Create new option group for target version
- Copy the options  to target option group
- Perform in-place upgrade of RDS instance by attaching new parameter group and option group
- Reboot the RDS instance

# what is not covered in the automation ?

When RDS is upgraded, all existing databases remain at their original database compatibility level. For example, if an instance is upgraded from SQL Server 2014 to SQL Server 2016, all existing databases have a compatibility level of 120. Any new database created after the upgrade have compatibility level 130.
You can change the compatibility level of a database by using the ALTER DATABASE command. For example, to change a database named `exampleDB` to be compatible with SQL Server 2014, issue the following command:

`ALTER DATABASE exampleDB SET COMPATIBILITY_LEVEL = 120`
            


# Prerequisites
- AWS CLI V2 version
- Python latest version
- RDS Instance to upgrade


> **⚠️ Note**
>
>This automation tool can run only when compatible and supported values are passed. For more information, refer to [Amazon RDS for Microsoft SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html)
>
>Creating an RDS for SQL Server 2014 Multi-AZ deployment with MSDTC option fails because Multi-AZ does not support MSDTC
>
>Upgrading an RDS for SQL Server 2014 instance with SSAS enabled to RDS for SQL Server 2022 is not supported as SSAS is not supported for RDS for SQL Server 2022.
>
>If you have SSRS DB option enabled on the source RDS, make sure to provide permission on the SSRS Secrets's resource policy to the new Option Group name, that you will pass during the script execution (example : SQL-RDS-2022-OG) in Secrets manager. Only then SSRS copy will be successful. For more information, refer to [Support for SQL Server Reporting Services in Amazon RDS for SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.SSRS.html)
>
>If you are running on SQL Server 2014 with Multi-AZ  and trying to upgrade to SQL Server 2022 this fails. You need to either convert Multi-AZ to Single-AZ or upgrade to intermediate version before upgrading to RDS for SQL Server 2022. This tool can't carry out Multi-AZ to Single-AZ conversion. Once you manually convert them you can rerun this tool.
>
>Make sure to evaluate and remove any parameters that are not needed in the upgraded version. This tool copies all the parameters from source to target version.
>
>If you are on a Linux environment, modify line 272 & 314 from `py db_options.py`  to `python db_options.py` for a successful run. If you are running from windows environment no changes required.

## How to Run this ?

Execute this shell script `rds_upgrade.sh` and provide requested inputs. Take a break! The tool takes care of the upgrade.

## What does each file do ?

- `rds_upgrade_2014.sh` This is the main file that executes the upgrade.
- `db_options.py` This python file performs json parsing and creates an output that serves as input for option group and parameter group creation. 
- `og_input.json` & `og_output.json` create the option group.
- `source_pg.json` creates the parameter group.



## Sample input and output. 

source_db_instance_identifier="rds2014"
region="us-east-2"
target_db_parameter_group_name="test-upgrade-pg-sql22"
target_db_parameter_group_family="sqlserver-se-16.0"
target_option_group_name="test-upgrade-ogsql22"
target_engine_version="16.00.4095.4.v1"

## Known Errors

While using custom option group, if no option was added on the source, below error will occur but the process will continue to run.

>**⚠️ An error occurred (InvalidParameterValue) when calling the ModifyOptionGroup operation: At least one option must be added, modified, or removed.**

