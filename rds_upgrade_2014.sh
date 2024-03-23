#Author Aravind Kumar Hariharaputran
#Version 1
#Date : 03/04/2024


rm -f upgrade_output.log
echo -e "Welcome to RDSUpgrade Tool\n">>upgrade_output.log
date '+%Y-%m-%d %H:%M:%S' >>upgrade_output.log
start=`date +%s`


source_db_instance_identifier='sql2016-maz'
region='us-east-2'
source_db_parameter_group_name=''
source_engineversion=''
source_db_parameter_group_family=''
source_engineversion=''
target_db_parameter_group_name='test-upgrade-pg16'
target_db_parameter_group_family='sqlserver-se-16.0'
target_option_group_name='test-upgrade-og16'
target_engine_name='sqlserver-se'
target_major_engine_version='16.00'
target_engine_version='16.00.4095.4.v1'
low_mzvalue_true="true"
low_mzvalue_false="false"

: <<'END_COMMENT'

echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo "AWS SQL RDS INPLACE-UPGRADE" | sed  -e :a -e "s/^.\{1,$(tput cols)\}$/ & /;ta" | tr -d '\n' | head -c $(tput cols)  
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------------------------------------------------------------------------------------------

echo "AWS SQL RDS INPLACE-UPGRADE" | sed  -e :a -e "s/^.\{1,$(tput cols)\}$/ & /;ta" | tr -d '\n' >>upgrade_output.log 


echo "Enter Source RDS Instance identifier"
read source_db_instance_identifier
echo -e "\nRDS Instance identifier $source_db_instance_identifier">>upgrade_output.log 


echo "Enter Source RDS Instance AWS Region"
read region
echo -e "RDS Instance AWS Region $region">>upgrade_output.log

echo "Enter RDS Instance target parameter group name if you are using custom parameter. If you are using default just hit enter"
read target_db_parameter_group_name
echo -e "RDS Instance target parameter group name $target_db_parameter_group_name">>upgrade_output.log

echo "Enter RDS Instance target parameter group family(Example:sqlserver-se-15.0)"
read target_db_parameter_group_family
echo -e "RDS Instance target parameter group family $target_db_parameter_group_family">>upgrade_output.log

echo "Enter RDS Instance target option group name if you are using custom option group. If you are using default just hit enter"
read target_option_group_name
echo -e "RDS Instance target option group name $target_option_group_name">>upgrade_output.log

echo "Enter RDS Instance target engine version(Example:15.00.4345.5.v1)"
read target_engine_version
echo -e "RDS Instance target engine version $target_engine_version">>upgrade_output.log

END_COMMENT

sql2014=12
sql2016=13
sql2017=14
sql2019=15
sql2022=16
source_engineversion_temp=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].EngineVersion'|sed 's/[^0-9]//g'`
source_engineversion=${source_engineversion_temp:0:3}
target_db_parameter_group_family_temp=$target_db_parameter_group_family
target_engine_name=${target_db_parameter_group_family_temp:0:12}
target_major_engine_version="${target_db_parameter_group_family_temp:13:17}0"
target_major_engine_version_maz_temp=$target_major_engine_version
target_major_engine_version_maz=${target_major_engine_version_maz_temp:0:2}
echo -e "\nSource Engine Major version: $source_engineversion">>upgrade_output.log
echo -e "\nTareget Engine Major Version MAZ:$target_major_engine_version_maz">>upgrade_output.log
echo -e "\nTarget Engine Name: $target_engine_name">>upgrade_output.log

multiaz=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].MultiAZ|[0]'`
echo "RDS MultiAZ: $multiaz">>upgrade_output.log
lis_endpoint=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].ListenerEndpoint.Address|[0]'|sed -r 's/"//g'`
echo "Listener  endpoint: $lis_endpoint">>upgrade_output.log
echo "Tareget Major Version $target_major_engine_version">>upgrade_output.log



if [[ ($lis_endpoint =~ (null)) && ($multiaz =~ ("true")) && ($target_major_engine_version_maz -eq 16) ]]; then   
    echo "Target Major Engine version  is $target_major_engine_version ,SQL Server 2022. As per the upgrade path to SQL Server 2022, MultiAZ should be converted to SingleAZ first.Please convert that in the console and rerun this tool"
    break
    else
    echo "Configuration looks good for the upgrade path. Continuing the process....!"
    ##############################################################################################################################################################################################################################################
    ##Parameter and Option Group handling
    ##############################################################################################################################################################################################################################################

    echo Getting the source parameter group name from RDS instance>>upgrade_output.log 
    source_db_parameter_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBParameterGroups[].DBParameterGroupName|[0]'`
    source_db_parameter_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_parameter_group_name"`
    echo $source_db_parameter_group_name>>upgrade_output.log 
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

    echo Getting the source option group name from RDS instance>>upgrade_output.log 
    source_db_option_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region  --query 'DBInstances[*].OptionGroupMemberships[].OptionGroupName|[0]'`
    source_db_option_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_option_group_name"`
    echo $source_db_option_group_name>>upgrade_output.log 
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

    default_pg='(default.)' 

    if [[ $source_db_parameter_group_name =~ $default_pg ]]; then
        echo 'Default ParameterGroup found on the source. No new ParameterGroup will be created. Continuing..'>>upgrade_output.log 
        else 
        echo "Custom ParameterGroup $source_db_parameter_group_name found on the source.">>upgrade_output.log
        echo "Creating new parameter group $target_db_parameter_group_name for target version">>upgrade_output.log
        aws rds create-db-parameter-group  --db-parameter-group-name $target_db_parameter_group_name  --region $region --db-parameter-group-family $target_db_parameter_group_family --description 'SQL RDS Upgrade ParameterGroup'>>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        echo "Selecting only modified parameters from  the source">>upgrade_output.log
        aws rds describe-db-parameters --db-parameter-group-name $source_db_parameter_group_name --region $region  --query "Parameters[?Source=='user']" --output json>source_pg.json
        echo "Copying the modified parameters to the target">>upgrade_output.log
        aws rds modify-db-parameter-group --db-parameter-group-name $target_db_parameter_group_name --region $region --parameters file://source_pg.json
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
    fi

    default_og='(default.)'

    if [[ $source_option_group_name =~ $default_og ]]; then
        echo 'Default OptionGroup found on the source. No new OptionGroup will be created. Continuing..'>>upgrade_output.log
        else 
        echo 'Custom OptionGroup $source_db_option_group_name found on the source.'>>upgrade_output.log
        echo "Creating new Option group $target_option_group_name for target version">>upgrade_output.log
        aws rds create-option-group  --option-group-name $target_option_group_name  --region $region  --engine-name $target_engine_name --major-engine-version $target_major_engine_version --option-group-description 'SQL RDS Upgrade optionGroup'>>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log  
        echo "Copying the options from the source option group to the target">>upgrade_output.log
        aws rds describe-option-groups --option-group-name $source_db_option_group_name --region $region  --query "OptionGroupsList[*].Options">og_input.json
        py db_options.py
        aws rds add-option-to-option-group --option-group-name $target_option_group_name --region $region --options file://og_output.json>>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log

    fi
    ##############################################################################################################################################################################################################################################
    ##InPlace Upgrade 
    ##############################################################################################################################################################################################################################################


    echo "Performing In Place upgrade now">>upgrade_output.log
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
    while true
    do  
    sleep 30
    dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBInstanceStatus|[0]')
    dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
        if [ ${dbstatus} == "available" ];then
                break;
            else
                echo "Pease wait DB is not in available state">>upgrade_output.log
                echo "Pease wait DB is not in available state"
                date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
                sleep 30
        fi
    done
    aws rds   modify-db-instance --db-instance-identifier $source_db_instance_identifier --region $region --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>>upgrade_output.log
    while true;
    do
        sleep 30
        dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBInstanceStatus|[0]')
        dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
        if [ ${dbstatus} == "available" ];then
            break;
        else
            echo "Upgrade is in progress . Please wait">>upgrade_output.log
            echo "Upgrade is in progress . Please wait"
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            sleep 30
        fi
    done
    echo "Rebooting RDS instance">>upgrade_output.log
    aws rds reboot-db-instance --db-instance-identifier $source_db_instance_identifier --region $region>>/dev/null
    while true;
    do
        sleep 30
        dbstatus=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBInstanceStatus|[0]')
        dbstatus=`sed -e 's/^"//' -e 's/"$//' <<<"$dbstatus"`
        if [ ${dbstatus} == "available" ];then
            break;
        else
            echo "Reboot is in progress . Please wait">>upgrade_output.log
            echo "Reboot is in progress . Please wait"
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            sleep 30
        fi
    done

    echo "RDS instance's SQL Server Engine after upgrade">>upgrade_output.log 
    source_engineversion=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].EngineVersion'`
    source_engineversion=`sed -e 's/^"//' -e 's/"$//' <<<"$source_engineversion"`
    echo $source_engineversion>>upgrade_output.log 


    end=`date +%s`
    expr=$((end-start))
    echo 'Execution time in HH MM SS' >>upgrade_output.log
    echo $((expr/3600)) $((expr%3600/60)) $((expr%60))>>upgrade_output.log
fi

