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
key_name                = "wot-wop-prod"

# Region will be either us-east-1 or us-west-2
aws_region              = "us-west-2"

# Application Instance Type can be found on the Deployment Spread Sheet
appinstance_type        = "t3.large"

# Enter the number of App Instances to be deployed should be at least 1
app_instance_count      = "2"

# Enter the name of the customer.  Make sure there are no spaces.
customer_name           = "WideOrbit-WOP-Test"

# Enter the environment (PROD, DEV, TST, UAT, STG)
envrionment             = "TST"

# Enter the App Role (APP)
app_role                = "APP"

# Enter the CIDR provided by the Spread Sheet
cidr_block              = "10.3.6.32/27"

# Enter the DNS name provided by the spread sheet only enter the first name (ex: na-11111-100-p)
record_set_name         = "na-231520-100-t"

# Enter the APP Computer Name excluding the number (ex: mrc-avatrapvp)
app_computer_name       = "wot-aorpgapvt"

# Enter the name of the DB.  It should be 8 or less characters in length and all uppercase
rds_db_name             = "WOTTST"

# Enter the Client OU that has been created in Active Directory.  Make sure there are no spaces.
client_ou               = "Test"

# Enter the amount of storage to allocate, in GBs, to the RDS instance
rds_storage             = 40

# Enter the name of the Master User Account.  By default use womaster
rds_user                = "womaster"

# Enter the instance type to be used by RDS for Oracle.  Use db.m5.large unless told otherwise.
rds_instance            = "db.t3.large"

# Enter Backup Rention Period for RDS Database.  Default is 7.
rds_backup_retention    = 7

# Enter RDS Backup Window.  Default is 03:00-06:00
rds_backup_window       = "03:00-06:00"

# Enter RDS Maintenance Window.  Default is "Sun:06:00-Sun:09:00"
rds_mainteance_window   = "Sun:06:00-Sun:09:00"

# Enter Storage Type.  Default is to use gp2
rds_storage_type        = "gp2"

# Enter Oracle Engine to use.  Default is oracle-se2
rds_engine              = "oracle-se2"

# Enter Oracle Engine Version to use.  Current default is "12.2.0.1.ru-2019-01.rur-2019-01.r1"
rds_engine_vers         = "12.2.0.1.ru-2019-01.rur-2019-01.r1"

# Enter AMI type to be used by the DB Server
#    win2016_base_ami
ami_type                = "win2016_base_ami"