#!/usr/bin/env bash
# Get content urls from alfresco database and generate mock content

# ####################################################################################### #
# 							  *****	Prerequisites *****									  #
#																						  #
# 1) Execute the mimetypeMapping.sh to generate your mimetype_maping.txt file. 			  #
# Mappings will be automatically generated based on existing mappings found in the 		  #
# base_mimemaping.txt file. If a mapping does not exist, the mapping will be equal to 	  #
# NOT_FOUND. You will need to manually update these entries								  #
#																						  #
# 2) The alf_node_props_query will run faster if you create a temp index and optimize	  #
# tables																				  #
#																						  #
# SHOW INDEX FROM alf_node_properties;													  #
# CREATE INDEX idx_string_value ON alf_node_properties(string_value(120));				  #
# OPTIMIZE TABLE alf_node_properties;													  #
#																						  #
# Drop index after creating mock content....											  #
#																						  #
# DROP INDEX idx_string_value ON alf_node_properties;									  #
# SHOW INDEX FROM alf_node_properties;													  #
# ####################################################################################### #

# Global Variables
base_dir=<my_base_directory>

test_result_limit=100
log_file=$base_dir/content_generator.log

# Alfresco Variables
contentstore_dir=$base_dir/alf_data/contentstore

# Mimetype Variables
mock_content_dir=$base_dir/data
mimetype_map_file=$mock_content_dir/mimetype_mapping.txt


# Check Test Mode
echo "Run in test mode (yes/no)?"
read test_mode_input
shopt -s nocasematch
case "$test_mode_input" in
  y|yes) echo "Mock Content Generator running in test mode.
  "
	test_mode=true;;
  n|no) echo "CAUTION: Content Generator running in full mode.
  "
	test_mode=false;;
  * ) echo "Incorrect value provided for test mode. Please enter yes or no." 
  exit 1;; 
esac

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
if [ -z $db_name ]; 
	then	
		echo "Database name was not entered. Please provide a valida database name."
		exit 1
fi

#Oracle Variables
sqlplus_command="sqlplus -s $db_user/$db_password@$db_host/$db_name"
sqlplus_options="SET feedback off verify off heading off pagesize 0 linesize 200"

# MySQL Variables
mysql_command="mysql --user=$db_user --password=$db_password --host $db_host $db_name --batch --raw --disable-column-names"

# Output to log and console
log()
{
	# Check if log file exists
	if [ -f $log_file ]; then
		# Roll log file over if the size is greater than 5mb
		log_size=$(find $log_file -size +5M)
		if [ -z $log_size ]; then
				current_time=$(date +%F-%T)
				# echo "$current_time - $*" > $log_file
				echo "$current_time - $*" | tee -a $log_file 
			else
				cp $log_file $log_file.$(date +%Y.%m.%d.%H.%M.%S).bak
				rm $log_file
		fi
		else
			touch $log_file
	fi
}

# Set queries according to database type and test mode value
setQueries()
{
	# Check if database type is equal to MySQL
	if [ $db_type == "mysql" ]; then
			db_command=$mysql_command
			# Content URL Query Variables. If test_mode=true LIMIT results to value define in the test_result_limit variable
			if [ $test_mode == true ]; then
					alf_node_props_query="SELECT substr(string_value, 20) FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%' LIMIT $test_result_limit;"
					alf_content_url_query="SELECT substr(cu.content_url,9) as url, m.mimetype_str FROM alf_content_data cd, alf_mimetype m, alf_content_url cu WHERE m.id = cd.content_mimetype_id and cd.content_url_id = cu.id LIMIT $test_result_limit;"
				else
					alf_node_props_query="SELECT substr(string_value, 20) FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%';"
					alf_content_url_query="SELECT substr(cu.content_url,9) as CONTENT_URL, m.mimetype_str FROM alf_content_data cd, alf_mimetype m, alf_content_url cu WHERE m.id = cd.content_mimetype_id and cd.content_url_id = cu.id;"
			fi
	# Database type is Oracle
	else		
		db_command=$sqlplus_command
		# Content URL Query Variables. If test_mode=true limit (<= rownum) results to value define in the test_result_limit variable
		if [ $test_mode == true ]; then			
				alf_node_props_query="$sqlplus_options
				column CONTENT_URL format a65
				column MIMETYPE format a100
				SELECT regexp_substr(string_value,'[^|]+',20) AS CONTENT_URL, substr(regexp_substr(string_value,'[^|]+',20,2),10) AS MIMETYPE FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%' AND rownum <= $test_result_limit ORDER BY CONTENT_URL;"
				alf_content_url_query="SET feedback off verify off heading off pagesize 0
				SELECT substr(cu.content_url,9) as CONTENT_URL, m.mimetype_str FROM alf_content_data cd, alf_mimetype m, alf_content_url cu WHERE m.id = cd.content_mimetype_id and cd.content_url_id = cu.id AND rownum <=  $test_result_limit ORDER BY CONTENT_URL;"
			else
				alf_node_props_query="$sqlplus_options
				column CONTENT_URL format a65
				column MIMETYPE format a100
				SELECT regexp_substr(string_value,'[^|]+',20) AS CONTENT_URL, substr(regexp_substr(string_value,'[^|]+',20,2),10) AS MIMETYPE FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%' ORDER BY CONTENT_URL;"
				alf_content_url_query="SET feedback off verify off heading off pagesize 0
				SELECT substr(cu.content_url,9) as CONTENT_URL, m.mimetype_str FROM alf_content_data cd, alf_mimetype m, alf_content_url cu WHERE m.id = cd.content_mimetype_id and cd.content_url_id = cu.id ORDER BY CONTENT_URL;"
		fi
	fi
}

executeQuery()
{	
	if [ $db_type == "mysql" ]; then
		# Get content urls from alf_content_url and create mock files
		alf_content_url_explain=$(echo "EXPLAIN $1" | $db_command)
		log "Explain Result: $alf_content_url_explain"
	fi
	log "Executing Query: $1"
	echo "$1" | $db_command |
	while read content_url mimetype;
	do	
		# Set row count
		result_count=$((result_count+1))
		log "$(($result_count))) Row: $content_url	$mimetype"
		
		# grep for mimetype in the mimetype map file
		mimetype_mapping=$(grep -w $mimetype $mimetype_map_file)
		
		# Remove leading and trailing white spaces and carriage returns, then get the mock file value after the = delimeter 
		if [ $mimetype == "application/ms-infopath.xml" ]; then
				mock_file=$(echo ${mimetype_mapping##*=} | sed -e 's/^ *//g;s/ *$//g')
			else
				mock_file=$(echo ${mimetype_mapping##*=} | sed -e 's/^ *//g;s/ *$//g;s/.$//')
		fi
		# Set source and target file variables
		source_file=$mock_content_dir/$mock_file
		target_file=$contentstore_dir/$content_url

		# Create Path from content_url before the first slash, then copy source file to target file
		log "Copying $source_file to $target_file"		
		mkdir -p $contentstore_dir/${content_url%/*}
		cp $source_file $target_file
	done
}

# Set queries according to database type and test mode value
setQueries

# Execute alf_node_props query
executeQuery "$alf_node_props_query"

# Only execute the alf_content_url query if the Alfresco version is greater than 3.2. 
# alf_mimetype, alf_content_data, and the new alf_content_url table were introduced in version 3.2 with the AlfrescoPostCreate-3.2-ContentTables.sql script
if [[ $alfresco_version > 3.2 ]]; then
	executeQuery "$alf_content_url_query"
fi

log "Total files generated: $(find $contentstore_dir -type f | wc -l)"
