#!/bin/bash
# Create mimemap.txt file for use with the contentGenerator.sh script

base_dir=<my_base_directory>

# Mimetype Variables
mock_content_dir=$base_dir/data
mimetype_map_file=$mock_content_dir/mimetype_mapping.txt
base_mimetype_map_file=$mock_content_dir/base_mimetype_mapping.txt

# Check Alfresco version
echo "Enter Alfresco Version"
read alfresco_version
if [ -z $alfresco_version ]; then	
		echo "No Alfresco version provided. Please provide a valid Alfresco version"
		exit 1
fi

# Check database type
echo "Enter database type ('oracle' or 'mysql'):"
read db_type
shopt -s nocasematch
case "$db_type" in
  oracle|ora) echo "Using database type: Oracle.
  "
	db_type=oracle;;
  mysql) echo "Using database type: MySQL.
  "
	db_type=mysql;;
  * ) echo "Incorrect value provided for database type. Please enter 'oracle' or 'mysql'." 
  exit 1;; 
esac

# Check database hostname
echo "Enter database hostname:"
read db_host
if [ -z $db_host ]; then	
		echo "Database hostname was not entered. Please provide a valida database hostname."
		exit 1
fi

# Check database username
echo "Enter database username:"
read db_user
if [ -z $db_user ]; then	
		echo "Database username was not entered. Please provide a valida database username."
		exit 1
fi

# Check database password
echo "Enter database password:"
stty -echo
read db_password
stty echo
if [ -z $db_password ]; then	
		echo "Database user password was not entered. Please provide a valid database password."
		exit 1
fi

# Check database name
echo "Enter database name:"
read db_name
if [ -z $db_name ]; then	
		echo "Database name was not entered. Please provide a valida database name."
		exit 1
fi

#Oracle Variables
sqlplus_command="sqlplus -s $db_user/$db_password@$db_host/$db_name"
sqlplus_options="SET feedback off verify off heading off pagesize 0 linesize 120"

mysql_command="mysql --user=$db_user --password=$db_password --host $db_host $db_name --batch --raw --disable-column-names"

setQueries()
{
	# Check if database type is equal to MySQL
	if [ $db_type == "mysql" ]; then
			db_command=$mysql_command
			alf_mimetype_query="SELECT DISTINCT mimetype_str FROM alf_mimetype;"
			alf_node_props_query="SELECT DISTINCT mimetype_str FROM alf_mimetype;"
	# Database type is Oracle
	else		
		db_command=$sqlplus_command
		alf_node_props_query="$sqlplus_options
		SELECT DISTINCT substr(regexp_substr(string_value,'[^|]+',20,2),10) AS MIMETYPE FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%';"
	fi
}

executeQuery()
{
	echo "$1" | $db_command |
	while read mimetype ;																	  
	do			
		echo "Found mimetype: $mimetype"
		mimetype_mapping=$(grep -w $mimetype $base_mimetype_map_file | head -n 1)	
		if [ -z $mimetype_mapping ]; then
				echo "$mimetype=NOT_FOUND" | tee -a $mimetype_map_file  
			else		
				echo "$mimetype_mapping" | tee -a $mimetype_map_file 
		fi
	done
}

# Set queries according to database type and test mode value
setQueries

# Execute alf_node_props query
executeQuery "$alf_node_props_query"

# Only execute the alf_content_url query if the Alfresco version is greater than 3.2. 
# alf_mimetype, alf_content_data, and the new alf_content_url table were introduced in version 3.2 with the AlfrescoPostCreate-3.2-ContentTables.sql script
if [[ $alfresco_version > 3.2 ]]; then
	executeQuery "$alf_mimetype_query"
fi
