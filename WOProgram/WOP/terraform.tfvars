key_name                = "mrc-key-prod"
aws_region              = "us-east-1"
appinstance_type        = "t3.large"
dbinstance_type         = "t3.xlarge"
db_instance_count       = "1"
app_instance_count      = "2"
customer_name           = "MRC-Services"
envrionment             = "PROD"
db_role                 = "DB"
app_role                = "APP"
cidr_block              = "10.4.5.96/27"
record_set_name         = "na-13182-100-p"
db_computer_name        = "mrc-avapgdbvp"
app_computer_name       = "mrc-avapgapvp"
#appdblb In a single server deployment 1 otherwise 0
appdblb                 = "0"
#applb In a single server deployment 0 otherwise 1
applb                   = "1"
client_ou               = "Test"
#ami_type Choices:
#       win2016_base_ami
#       win2016_sql_2016_std_ami
#       win2016_sql_2016_ent_ami
#       win2016_sql_2016_web_ami
ami_type                = "win2016_base_ami"