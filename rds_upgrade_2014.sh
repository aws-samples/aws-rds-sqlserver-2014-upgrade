#Author Aravind Kumar Hariharaputran
#Version 1
#Date : 03/04/2024

rm -f upgrade_output.log
echo -e "Welcome to RDSUpgrade Tool\n">>upgrade_output.log
date '+%Y-%m-%d %H:%M:%S' >>upgrade_output.log
start=`date +%s`


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

echo "Enter RDS Instance target parameter group name to use custom parameter group . To use default , enter 'default'"
read target_db_parameter_group_name
echo -e "RDS Instance target parameter group name $target_db_parameter_group_name">>upgrade_output.log

echo "Enter RDS Instance target option group name to use custom option group. To use default , enter 'default'"
read target_option_group_name
echo -e "RDS Instance target option group name $target_option_group_name">>upgrade_output.log


echo "Enter RDS Instance target engine version(Example:15.00.4345.5.v1)"
read target_engine_version
echo -e "RDS Instance target engine version $target_engine_version">>upgrade_output.log


if [ -z "$source_db_instance_identifier" ]; then   
    echo "Source RDS Instance identifier is NULL. Re-run the process . Exiting.">>upgrade_output.log
    echo "Source RDS Instance identifier is NULL. Re-run the process . Exiting."
    exit
    elif [ -z "$region" ]; then   
        echo "region is NULL. Re-run the process . Exiting.">>upgrade_output.log
        echo "region is NULL. Re-run the process . Exiting."
        exit
    elif [ -z "$target_db_parameter_group_name" ]; then   
        echo "RDS Instance target parameter group name is NULL. Re-run the process . Exiting.">>upgrade_output.log
        echo "RDS Instance target parameter group name is NULL. Re-run the process . Exiting."
        exit
    elif [ -z "$target_option_group_name" ]; then   
        echo "RDS Instance target option group name is NULL. Re-run the process . Exiting.">>upgrade_output.log
        echo "RDS Instance target option group name is NULL. Re-run the process . Exiting."
        exit
    elif [ -z "$target_engine_version" ]; then   
        echo "RDS Instance target engine version is NULL. Re-run the process . Exiting.">>upgrade_output.log
        echo "RDS Instance target engine version is NULL. Re-run the process . Exiting."
        exit
    else 
     echo "Null Value validation completed. None of the parameters are Null. Proceeding further">>upgrade_output.log
     echo "Null Value validation completed. None of the parameters are Null. Proceeding further"
fi



echo "Kindly monitor upgrade_output.log for more verbose logging"


rds_name_validation=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBInstanceIdentifier|[0]')
rds_name_validation=`sed -e 's/^"//' -e 's/"$//' <<<"$rds_name_validation"`


if [[ (($rds_name_validation =~ ($source_db_instance_identifier))) ]]; then   
    echo "RDS Name and region validation completed. Proceeding further">>upgrade_output.log
    echo "RDS Name and region validation completed. Proceeding further"
    else
    echo "RDS Name or region invalid. Please check the error, exiting ...!">>upgrade_output.log
    echo "RDS Name or region invalid. Please check the error, exiting ...!"
    exit
fi 



sql2014=12
sql2016=13
sql2017=14
sql2019=15
sql2022=16
source_engineversion_temp=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].EngineVersion'|sed 's/[^0-9]//g'`
source_engineversion=${source_engineversion_temp:0:3}
target_engineversion_temp=$target_engine_version
target_engineversion_db_family=${target_engineversion_temp:0:4}

target_db_parameter_group_family_eng=$(aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region  --query 'DBInstances[*].Engine|[0]')
target_db_parameter_group_family_eng=`sed -e 's/^"//' -e 's/"$//' <<<"$target_db_parameter_group_family_eng"`
target_db_parameter_group_family=$target_db_parameter_group_family_eng-$target_engineversion_db_family


target_db_parameter_group_family_temp=$target_db_parameter_group_family
target_engine_name=${target_db_parameter_group_family_temp:0:12}

target_major_engine_version="${target_db_parameter_group_family_temp:13:17}0"
target_major_engine_version_maz_temp=$target_major_engine_version
target_major_engine_version_maz=${target_major_engine_version_maz_temp:0:2}


echo -e "\nSource Engine Major version: $source_engineversion">>upgrade_output.log
echo -e "\nTarget Engine Major Version MAZ:$target_major_engine_version_maz">>upgrade_output.log
echo -e "\nTarget Engine Name: $target_engine_name">>upgrade_output.log
echo -e "\nTarget parameter group family: $target_db_parameter_group_family">>upgrade_output.log


multiaz=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].MultiAZ|[0]'`
echo "RDS MultiAZ: $multiaz">>upgrade_output.log
lis_endpoint=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].ListenerEndpoint.Address|[0]'|sed -r 's/"//g'`
echo "Listener  endpoint: $lis_endpoint">>upgrade_output.log
echo "Tareget Major Version $target_major_engine_version_maz">>upgrade_output.log


if [[ ($lis_endpoint =~ (null)) && ($multiaz =~ ("true")) && ($target_major_engine_version_maz -eq 16) ]]; then   
    echo "Target Major Engine version  is $target_major_engine_version ,SQL Server 2022. As per the upgrade path to SQL Server 2022, MultiAZ should be converted to SingleAZ first. Please convert that in the console and rerun this tool"
    echo "Target Major Engine version  is $target_major_engine_version ,SQL Server 2022. As per the upgrade path to SQL Server 2022, MultiAZ should be converted to SingleAZ first. Please convert that in the console and rerun this tool">>upgrade_output.log
    break    
    else
    echo "Proceeding further"
    ##############################################################################################################################################################################################################################################
    ##Parameter and Option Group handling
    ##############################################################################################################################################################################################################################################

    echo Getting the source parameter group name from RDS instance>>upgrade_output.log 
    echo "Getting the source parameter group name from RDS instance"
    source_db_parameter_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region --query 'DBInstances[*].DBParameterGroups[].DBParameterGroupName|[0]'`
    source_db_parameter_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_parameter_group_name"`
    echo $source_db_parameter_group_name>>upgrade_output.log 
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

    echo Getting the source option group name from RDS instance>>upgrade_output.log 
    echo "Getting the source option group name from RDS instance"
    source_db_option_group_name=`aws rds describe-db-instances --db-instance-identifier $source_db_instance_identifier --region $region  --query 'DBInstances[*].OptionGroupMemberships[].OptionGroupName|[0]'`
    source_db_option_group_name=`sed -e 's/^"//' -e 's/"$//' <<<"$source_db_option_group_name"`
    echo $source_db_option_group_name>>upgrade_output.log 
    date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log 

    default_pg='(default.)' 
    build_default_pg='default.'  
    build_default_og_start='default:'  
    build_default_og_end='-00'




    if [[ (($source_db_parameter_group_name =~ $default_pg) && ($target_db_parameter_group_name =~ (default))) ]]; then
        echo 'Default ParameterGroup found on the source. Default parametergroup requested for upgrade. Continuing with Default paramtergroup.'>>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        elif [[ (("$source_db_parameter_group_name" != "$default_pg")) && ($target_db_parameter_group_name =~ (default)) ]]; then
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            echo 'Custom ParameterGroup found on the source. But Default parametergroup requested for upgrade. Continuing with Default paramtergroup.'>>upgrade_output.log 
        elif [[ (($source_db_parameter_group_name =~ $default_pg) && ("$target_db_parameter_group_name" != "default")) ]]; then
            echo "Default ParameterGroup found on the source. But Custom parametergroup requested for upgrade. Continuing with Custom paramtergroup.">>upgrade_output.log
            echo "Creating new parameter group $target_db_parameter_group_name for target version">>upgrade_output.log              
            aws rds create-db-parameter-group  --db-parameter-group-name $target_db_parameter_group_name  --region $region --db-parameter-group-family $target_db_parameter_group_family --description 'SQL RDS Upgrade ParameterGroup'>>upgrade_output.log
            create_db_pg1=$?
            echo "create_db_pg1 $create_db_pg1">>upgrade_output.log
            if [ $create_db_pg1 -eq 0 ]; then
                echo "DB Parameter Group successfully created. Moving forward"
                echo "DB Parameter Group successfully created. Moving forward">>upgrade_output.log
                elif [ $create_db_pg1 -eq 254 ]; then
                echo -e "DB Parameter Group already exists. Do you want to proceed with this Parameter group or Exit now.  Select (y/n):">>upgrade_output.log
                read -p "DB Parameter Group already exists. Do you want to proceed with this Parameter group or Exit now. Select (y/n):" pg_decision
                    if [ "$pg_decision" == "y" ] || [ "$pg_decision" == "Y" ]; then
                    echo "Proceeding with this Parameter group"
                    else
                    echo "Exiting now"
                    exit
                    fi
                else
                    echo "DB Parameter Group creation failed. Exiting"
                    exit

            fi             
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            echo "Selecting only modified parameters from  the source">>upgrade_output.log
            aws rds describe-db-parameters --db-parameter-group-name $source_db_parameter_group_name --region $region  --query "Parameters[?Source=='user']" --output json>source_pg.json
            echo "Copying the modified parameters to the target">>upgrade_output.log
            aws rds modify-db-parameter-group --db-parameter-group-name $target_db_parameter_group_name --region $region --parameters file://source_pg.json
            modify_db_pg1=$?
            echo "modify_db_pg1 $modify_db_pg1">>upgrade_output.log
            if [ $modify_db_pg1 -ne 0 ]; then
            echo "DB Parameter Group copy paramter failed. Exiting">>upgrade_output.log
            echo "DB Parameter Group copy paramter failed. Exiting"
            exit
            fi
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        else 
            echo "Custom ParameterGroup found on the source. Custom parametergroup requested for upgrade. Continuing with Custom paramtergroup.">>upgrade_output.log
            echo "Creating new parameter group $target_db_parameter_group_name for target version">>upgrade_output.log
            aws rds create-db-parameter-group  --db-parameter-group-name $target_db_parameter_group_name  --region $region --db-parameter-group-family $target_db_parameter_group_family --description 'SQL RDS Upgrade ParameterGroup'>>upgrade_output.log
            create_db_pg2=$?
            echo "create_db_pg2 $create_db_pg2">>upgrade_output.log
            if [ $create_db_pg2 -eq 0 ]; then
                echo "DB Parameter Group successfully created. Moving forward"
                echo "DB Parameter Group successfully created. Moving forward">>upgrade_output.log
                elif [ $create_db_pg2 -eq 254 ]; then
                echo -e "DB Parameter Group already exists. Do you want to proceed with this Parameter group or Exit now.  Select (y/n):">>upgrade_output.log
                read -p "DB Parameter Group already exists. Do you want to proceed with this Parameter group or Exit now. Select (y/n):" pg_decision
                    if [ "$pg_decision" == "y" ] || [ "$pg_decision" == "Y" ]; then
                    echo "Proceeding with this Parameter group"
                    else
                    echo "Exiting now"
                    exit
                    fi
                else
                    echo "DB Parameter Group creation failed. Exiting"
                    exit
            fi
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
            echo "Selecting only modified parameters from  the source">>upgrade_output.log
            aws rds describe-db-parameters --db-parameter-group-name $source_db_parameter_group_name --region $region  --query "Parameters[?Source=='user']" --output json>source_pg.json
            echo "Copying the modified parameters to the target">>upgrade_output.log
            aws rds modify-db-parameter-group --db-parameter-group-name $target_db_parameter_group_name --region $region --parameters file://source_pg.json
            modify_db_pg2=$?
            echo "modify_db_pg2 $modify_db_pg2">>upgrade_output.log
            if [ $modify_db_pg2 -ne 0 ]; then
            echo "DB Parameter Group modification failed. Exiting"
            echo "DB Parameter Group modification failed. Exiting">>upgrade_output.log
            exit
            fi
            date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log        
    fi


    default_og='(default.)'

    if [[ (($source_option_group_name =~ $default_og) && ($target_option_group_name =~ (default))) ]]; then
        echo 'Default OptionGroup found on the source. Default OptionGroup requested for upgrade.Continuing with Default OptionGroup.'>>upgrade_output.log
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        elif [[ (("$source_option_group_name" != "$default_og")) && ($target_option_group_name =~ (default)) ]]; then
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        echo 'Custom OptionGroup found on the source. But Default OptionGroup requested for upgrade. Continuing with Default OptionGroup.'>>upgrade_output.log 
        elif [[ (($source_option_group_name =~ $default_og) && ("$target_option_group_name" != "default")) ]]; then
        echo "Default OptionGroup $source_db_option_group_name found on the source.But Custom Optiongroup requested for upgrade. Continuing with Custom Optiongroup.">>upgrade_output.log
        echo "Creating new Option group $target_option_group_name for target version">>upgrade_output.log
        aws rds create-option-group  --option-group-name $target_option_group_name  --region $region  --engine-name $target_engine_name --major-engine-version $target_major_engine_version --option-group-description 'SQL RDS Upgrade optionGroup'>>upgrade_output.log
        create_db_og1=$?
        echo "create_db_og1 $create_db_og1">>upgrade_output.log
        if [ $create_db_og1 -eq 0 ]; then
            echo "DB Option Group successfully created. Moving forward"
            echo "DB Option Group successfully created. Moving forward">>upgrade_output.log
            elif [ $create_db_og1 -eq 254 ]; then
            echo -e "DB Option Group already exists. Do you want to proceed with this Option group or Exit now.  Select (y/n):">>upgrade_output.log
            read -p "DB group Group already exists. Do you want to proceed with this group group or Exit now. Select (y/n):" og_decision
                if [ "$og_decision" == "y" ] || [ "$og_decision" == "Y" ]; then
                echo "Proceeding with this Option group"
                else
                echo "Exiting"          
                exit
                fi
            else
                echo "DB Option Group creation failed. Exiting"
                exit
        fi

        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log  
        echo "Copying the options from the source option group to the target">>upgrade_output.log
        echo "Please ignore this message if you don't have SSRS option enabled in your source RDS but if you do, make sure to provide permission for the new option group in SSRS Secrets's resource policy.Look into Readme for more details"
        aws rds describe-option-groups --option-group-name $source_db_option_group_name --region $region  --query "OptionGroupsList[*].Options">og_input.json
        py db_options.py
        run_python1=$?
        echo "run_python1 $run_python1">>upgrade_output.log
        if [ $run_python1 -ne 0 ]; then
            echo "Python script to populate Option Group parameter failed. Exiting"
            echo "Python script to populate Option Group parameter failed. Exiting">>upgrade_output.log           
        fi
        aws rds add-option-to-option-group --option-group-name $target_option_group_name --region $region --options file://og_output.json>>upgrade_output.log
        add_otion1=$?
        echo "add_otion1 $add_otion1">>upgrade_output.log
        if [ $add_otion1 -ne 0 ]; then
            echo "Zero Options copied. Moving forward"
            echo "Zero Options copied. Moving forward">>upgrade_output.log
            exit
        fi
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log
        else
        echo "Default OptionGroup $source_db_option_group_name found on the source. But Custom Optiongroup requested for upgrade. Continuing with Custom Optiongroup.">>upgrade_output.log
        echo "Creating new Option group $target_option_group_name for target version">>upgrade_output.log
        aws rds create-option-group  --option-group-name $target_option_group_name  --region $region  --engine-name $target_engine_name --major-engine-version $target_major_engine_version --option-group-description 'SQL RDS Upgrade optionGroup'>>upgrade_output.log
        create_db_og2=$?
        echo "create_db_og2 $create_db_og2">>upgrade_output.log
        if [ $create_db_og2 -eq 0 ]; then
            echo "DB Option Group successfully created. Moving forward"
            echo "DB Option Group successfully created. Moving forward">>upgrade_output.log
            elif [ $create_db_og2 -eq 254 ]; then
            echo -e "DB Option Group already exists. Do you want to proceed with this Option group or Exit now.  Select (y/n):">>upgrade_output.log
            read -p "DB group Group already exists. Do you want to proceed with this group group or Exit now. Select (y/n):" og_decision
                if [ "$og_decision" == "y" ] || [ "$og_decision" == "Y" ]; then
                echo "Proceeding with this Option group"
                else
                echo "Exiting"          
                exit
                fi
            else
                echo "DB Option Group creation failed. Exiting"
                exit
        fi
        date '+%Y-%m-%d %H:%M:%S'>>upgrade_output.log  
        echo "Copying the options from the source option group to the target">>upgrade_output.log
        echo "Please ignore this message if you don't have SSRS option enabled in your source RDS but if you do, make sure to provide permission for the new option group in SSRS Secrets's resource policy.Look into Readme for more details"
        aws rds describe-option-groups --option-group-name $source_db_option_group_name --region $region  --query "OptionGroupsList[*].Options">og_input.json
        py db_options.py
        run_python2=$?
        echo "run_python2 $run_python2">>upgrade_output.log
        if [ $run_python2 -ne 0 ]; then
            echo "DB parameter failed to create exiting"
            echo "DB parameter failed to create exiting">>upgrade_output.log
            exit
        fi
        aws rds add-option-to-option-group --option-group-name $target_option_group_name --region $region --options file://og_output.json>>upgrade_output.log
        add_otion2=$?
        echo "add_otion2 $add_otion2">>upgrade_output.log
        if [ $add_otion2 -ne 0 ]; then
            echo "Zero Options copied. Moving forward"
            echo "Zero Options copied. Moving forward">>upgrade_output.log
        fi
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

    if [[ (("$target_db_parameter_group_name" =~ (default))) && ("$target_option_group_name" =~ (default)) ]]; then
        target_db_parameter_group_name=$build_default_pg$target_db_parameter_group_family
        target_option_group_name_build1=$build_default_og_start$target_db_parameter_group_family
        target_option_group_name_build1=${target_option_group_name_build1:0:23}
        target_option_group_name=$target_option_group_name_build1$build_default_og_end
        echo "Currently in default target parameter and default option group loop ">>upgrade_output.log
        aws rds   modify-db-instance --db-instance-identifier $source_db_instance_identifier --region $region --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>>/dev/null
        modify_db_inst1=$?
        echo "modify_db_inst1 $modify_db_inst1">>upgrade_output.log
        if [ $modify_db_inst1 -ne 0 ]; then
            echo "Upgrade DB instance failed. Exiting"
            echo "Upgrade DB instance failed. Exiting">>upgrade_output.log
            exit
        fi
        echo "Upgrade initiated . Please wait"
        while true;
        do
            sleep 60
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
        elif [[ (("$target_db_parameter_group_name" != "default")) && ($target_option_group_name =~ (default)) ]]; then
        target_option_group_name_build1=$build_default_og_start$target_db_parameter_group_family
        target_option_group_name_build1=${target_option_group_name_build1:0:23}
        target_option_group_name=$target_option_group_name_build1$build_default_og_end
        echo "Currently in custom target parameter and default option group loop ">>upgrade_output.log
        aws rds   modify-db-instance --db-instance-identifier $source_db_instance_identifier --region $region --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>>/dev/null
        modify_db_inst2=$?
        echo "modify_db_inst2 $modify_db_inst2">>upgrade_output.log
        if [ $modify_db_inst2 -ne 0 ]; then
            echo "Upgrade DB instance failed. Exiting"
            echo "Upgrade DB instance failed. Exiting">>upgrade_output.log
            exit
        fi
        echo "Upgrade initiated . Please wait"
        while true;
        do
            sleep 60
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
        elif [[ (($target_db_parameter_group_name =~ (default)) && ("$target_option_group_name" != "default")) ]]; then
        target_db_parameter_group_name=$build_default_pg$target_db_parameter_group_family        
        echo "Currently in default target parameter and custom option group loop ">>upgrade_output.log
        aws rds   modify-db-instance --db-instance-identifier $source_db_instance_identifier --region $region --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>>/dev/null
        echo "Upgrade initiated . Please wait"
        while true;
        do
            sleep 60
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
        else
        echo "Currently in custom target parameter and custom option group loop ">>upgrade_output.log
        aws rds   modify-db-instance --db-instance-identif $source_db_instance_identifier --region $region --engine-version $target_engine_version --db-parameter-group-name $target_db_parameter_group_name  --option-group-name $target_option_group_name --allow-major-version-upgrade --apply-immediately>>/dev/null
        modify_db_inst3=$?
        echo "modify_db_inst3 $modify_db_inst3">>upgrade_output.log
        if [ $modify_db_inst3 -ne 0 ]; then
            echo "Upgrade DB instance failed. Exiting"
            echo "Upgrade DB instance failed. Exiting">>upgrade_output.log
            exit
        fi        
        echo "Upgrade initiated . Please wait"
        while true;
        do
            sleep 60
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
    fi

    echo "Rebooting RDS instance">>upgrade_output.log
    aws rds reboot-db-instance --db-instance-identifier $source_db_instance_identifier --region $region>>/dev/null
    modify_db_inst2=$?
    echo "modify_db_inst2 $modify_db_inst2">>upgrade_output.log
    if [ $modify_db_inst2 -ne 0 ]; then
        echo "Reboot DB instance failed. Exiting"
        echo "Reboot DB instance failed. Exiting">>upgrade_output.log
        exit
    fi
    echo "Reboot initiated . Please wait"
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
    echo "$source_engineversion">>upgrade_output.log 
fi

    end=`date +%s`
    expr=$((end-start))
    echo 'Execution time in HH MM SS' >>upgrade_output.log
    echo $((expr/3600)) $((expr%3600/60)) $((expr%60))>>upgrade_output.log

