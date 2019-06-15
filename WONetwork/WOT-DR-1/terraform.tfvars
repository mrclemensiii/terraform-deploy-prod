key_name                = "wot-key-dr"
aws_region              = "us-east-1"
appinstance_type        = "t3.large"
dbinstance_type         = "t3.xlarge"
db_instance_count       = "1"
app_instance_count      = "0"
sg_from_port            = "9000"
sg_to_port              = "9000"
customer_name           = "WideOrbitTest"
envrionment             = "DR"
db_role                 = "DB"
app_role                = "APP"
cidr_block              = "10.4.6.64/27"
record_set_name         = "na-231520-101-r"
db_computer_name        = "wot-avatrdbvr"
app_computer_name       = "wot-avatrapvr"
#appdblb In a single server deployment 1 otherwise 0
appdblb                 = "1"
#applb In a single server deployment 0 otherwise 1
applb                   = "0"
client_ou               = "Test"
ami_type                = "win2016_sql_2016_std_ami"