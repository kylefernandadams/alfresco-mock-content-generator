AlfrescoMockContentGenerator
=====================
The AlfrescoMockContentGenerator project contains a set of shell scripts to be used for testing Alfresco upgrades and 
replicating environments when using the existing content store is not feasible. 

Disclaimer
==========
Use the AlfrescoMockContentGenerator tool at your own risk. The AlfrescoMockContentGenerator is not supported by Alfresco. It should only be used in development environments and for testing purposes. 

Instructions
============
1) Update the base_dir variables found in both the contentGenerator.sh and mimetypeMapping.sh. 
The base_dir is the directory in which the "data" directory is contained. This directory contains the mock content files,
the base_mimetype_mapping.txt template file and an example mimetype_mapping.txt file. The data directory can be found 
in the resources directory of this project.

2) Execute the mimetypeMapping.sh to generate your mimetype_maping.txt file.
Mappings will be automatically generated based on existing mappings found in the base_mimemaping.txt file.
If a mapping does not exist, the mapping will be equal to NOT_FOUND. You will need to manually update these entries	and 
provide a sample file with the following naming convention. a.my_missing_extension (Example: a.docx)

3) Run './contentGenerator.sh' and follow the instructions given by the command prompt

Sample Output
=============
Run in test mode (yes/no)?

yes

Mock Content Generator running in test mode.
  
Enter Alfresco Version:

4.1.4

Enter database type ('oracle' or 'mysql'):

mysql

Using database type: MySQL.
  
Enter database hostname:

localhost

Enter database username:

alfresco

Enter database password:

Enter database name:

alfresco

2013-04-26-15:36:29 - Executing Query: SELECT substr(string_value, 20) FROM alf_node_properties WHERE string_value LIKE 'contentUrl=store:%' LIMIT 100;

2013-04-26-15:36:29 - Explain Result: 1  SIMPLE	m	index	PRIMARY	mimetype_str	302	NULL	13	Using index
1	SIMPLE	cd	ref	fk_alf_cont_url,fk_alf_cont_mim	fk_alf_cont_mim	9	alfresco4129.m.id	157	Using where
1	SIMPLE	cu	eq_ref	PRIMARY	PRIMARY	8	alfresco4129.cd.content_url_id	1	NULL

2013-04-26-15:36:29 - Executing Query: SELECT substr(cu.content_url,9) as url, m.mimetype_str FROM alf_content_data cd, alf_mimetype m, alf_content_url cu WHERE m.id = cd.content_mimetype_id and cd.content_url_id = cu.id LIMIT 100;

2013-04-26-15:36:29 - 1) Row: 2013/3/5/9/39/d122abea-4847-4913-8e6b-f314bdf5f7a5.bin  application/acp

2013-04-26-15:36:29 - Copying /Developer/Code/ContentGeneratorShell/resources/data/a.acp to /Developer/Code/ContentGeneratorShell/resources/alf_data/contentstore/2013/3/5/9/39/d122abea-4847-4913-8e6b-f314bdf5f7a5.bin

...

2013-04-26-15:36:32 - 100) Row: 2013/2/25/21/52/b520ef7a-a6a9-47f6-af23-b05cda222643.bin  text/html

2013-04-26-15:36:32 - Copying /Developer/Code/ContentGeneratorShell/resources/data/a.html to /Developer/Code/ContentGeneratorShell/resources/alf_data/contentstore/2013/2/25/21/52/b520ef7a-a6a9-47f6-af23-b05cda222643.bin

2013-04-26-15:36:32 - Total files generated:       86


License
=======
Copyright (C) 2013 Alfresco Software Limited

This file is part of an unsupported extension to Alfresco.

Alfresco Software Limited licenses this file to you under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.




