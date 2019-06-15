###############################################################################################################
#
# This is file allows you to assign all needed variables for Terraform to run successfully
# It is important that all variables listed below have a value.  Even if one is not needed.
# As an example if you are deploying a single server environment with no Application Servers
# you still have to provide a name for the application server.  Just copy this file into the
# same terraform folder as the main.tf and variables.tf
#
###############################################################################################################

# Enter key in the following format Customer Initials - Application - Environment
key_name                = "tmo-wot-prod"

# Region will be either us-east-1 or us-west-2
aws_region              = "us-west-2"

# Application Instance Type can be found on the Deployment Spread Sheet
appinstance_type        = "t3.large"

# DB Instance Type can be found on the Deployment Spread Sheet
dbinstance_type         = "t3.xlarge"

# Enter the number of DB Instances to be deployed.  Should always be 1.
db_instance_count       = "1"

# Enter the number of App Instances to be deployed can be 0 in a single server environment
app_instance_count      = "3"

# Enter the ports to be used by the application.  In a single server or single App server environment
# both variables will be 9000.  In a multi-app server environment (ie App Servers > 1) increment the 
# ports as needed.
# Ex: 3 Application servers sg_from_port will be 9000 and sg_to_port will be 9002
sg_from_port            = "9000"
sg_to_port              = "9001"

# Enter the name of the customer.  Make sure there are no spaces.
customer_name           = "TestMeOut"

# Enter the environment (PROD, DEV, TST, UAT, STG)
envrionment             = "PROD"

# Enter the DB Role (DB or APPDB in a single server environment)
db_role                 = "DB"

# Enter the App Role (APP)
app_role                = "APP"

# Enter the CIDR provided by the Spread Sheet
cidr_block              = "10.3.6.96/27"

# Enter the DNS name provided by the spread sheet only enter the first name (ex: na-11111-100-p)
record_set_name         = "na-201315-100-p"

# Enter the DB Computer name excluding the number (ex: mrc-avatrdbvp)
db_computer_name        = "tmo-aortrdbvp"

# Enter the APP Computer Name excluding the number (ex: mrc-avatrapvp)
app_computer_name       = "tmo-aortrapvp"

# will this have a DR deployment? 1 for yes otherwise 0 for no
use_dr                      = "0"

# Enter DR CIDR provided by the Spread Sheet if there is one
dr_cidr_block           = "10.3.6.128/27"

# Enter the Client OU that has been created in Active Directory.  Make sure there are no spaces.
client_ou               = "Test"

# Enter AMI type to be used by the DB Server
#    win2016_base_ami
#    win2016_sql_2016_std_ami
#    win2016_sql_2016_ent_ami
#    win2016_sql_2016_web_ami
ami_type                = "win2016_sql_2016_std_ami"