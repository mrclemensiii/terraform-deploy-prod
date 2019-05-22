key_name                = "wot-key-prod"
aws_region              = "us-east-1"
appinstance_type        = "t3.large"
dbinstance_type         = "t3.xlarge"
db_instance_count       = "1"
app_instance_count      = "0"
customer_name           = "WideOrbitTest"
envrionment             = "PROD"
db_role                 = "DB"
app_role                = "APP"
cidr_block              = "10.4.6.32/27"
record_set_name         = "na-231520-100-p"
db_computer_name        = "WOT-AVATRDBVP"
app_computer_name       = "WOT-AVATRAPVP"
client_ou               = "Test"

#####################################################
#appdblb In a single server deployment 1 otherwise 0
appdblb                 = "1"

#applb In a single server deployment 0 otherwise 1
applb                   = "0"
#####################################################

#####################################################
#   Choose which AMI type for the Database server to
#   use.
#   Choices:
#       win2016_base_ami
#       win2016_sql_2016_std_ami
#       win2016_sql_2016_ent_ami
#       win2016_sql_2016_web_ami
ami_type                = "win2016_sql_2016_std_ami"
#####################################################