# SQLRDS2014Upgrade
SQL RDS Upgrade from 2014 to higher version

# What this Automation Tool does  ?

When you go through the SQL RDS Major version In Place upgrade journey by following [Major Version Upgrade](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.SQLServer.html) , you will need to follow series of manual process in order to perform a successful in place upgrade. For example Copy paramter group,option group and there is no AWS CLI command to perform this task in a automated way.

This process is a single-click deployment that will enable customers perform the task successfully with few user inputs.


# High level Steps

- Check upgrade path
- Create new parameter group for target version
- Copy the parameters to target parameter group 
- Create new option group for target version
- Copy the options  to target option group
- Perform Inplace upgrade of RDS instance attaching new parameter group and option group
- Reboot the RDS instance

# what is not covered ?

When RDS is upgraded, all existing databases remain at their original database compatibility level. For example, RDS is upgraded from SQL Server 2014 to SQL Server 2016, all existing databases have a compatibility level of 120. Any new database created after the upgrade have compatibility level 130.
You can change the compatibility level of a database by using the ALTER DATABASE command. For example, to change a database named customeracct to be compatible with SQL Server 2014, issue the following command:

`ALTER DATABASE customeracct SET COMPATIBILITY_LEVEL = 120`
            


# Prerequisites
- AWS CLI latest version
- Python latest version
- Source SQL RDS Instance to upgrade


> **⚠️ Note**
>
>Tool will successfully run  only when compatabile and supported values are passed. For more information , refer to [Amazon RDS for Microsoft SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html) for more information 
>
>If you are trying to enable MultiAZ on RDS for SQL Server 2014 that has MSDTC Option enabled, this will fail since MultiAZ is not supported when MSDTC is enabled.
>
>If you have SSAS enabled on RDS for SQL Server 2014 , if you try to upgrade to on RDS for SQL Server 2022, this will fail as SSAS is not supported in on RDS for SQL Server 2022.
>
>If you have SSRS DB option enabled on the source RDS,make sure to provide permission on the SSRS Secrets's resource policy to the new Option Group name, that you will pass during the script execution (example : SQL-RDS-2022-OG) in Secrets manager. Only then SSRS copy will be successful. For more information, refer to [Support for SQL Server Reporting Services in Amazon RDS for SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.Options.SSRS.html)
>
>If you are running on SQL Server 2014 with MultiAZ  and trying to upgrade to SQL Server 2022 this will fail . As per upgrade path you need to either convert Multi AZ to SingleAZ first or upgrade to intermediate verison before upgrading to 2022. MultiAZ to SingleAZ conversion is not handled by this tool. Once you manually convert them you can rerun this tool.
>
>Make sure to evaluate and remove any paramters that are not needed in the upgraded version . This tool will copy all the parameters from source to target version.
>
>If you are on Linux environment,modify line 157 from `py db_options.py`  to `python db_options.py` for a successful run. If you are running from windows environment no changes required. 

## How to Run this ?

All you need to do is , execute this shell script `rds_upgrade.sh` and provide requested inputs. Take a break ! We will take care of the upgrade.

## What does each file do ?

- `rds_upgrade_2014.sh` This is the main file that need to be run for executing the upgrade. 
- `db_options.py` This python file performs json parsing , creates an output that serve as input for option group and parameter group creation. 
- `og_input.json` & `og_output.json` are used to create option group.
- `source_pg.json` file is used to create parameter group.



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

