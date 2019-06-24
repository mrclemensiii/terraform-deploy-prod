variable "public_key_path" {
  description = <<DESCRIPTION
  Path to the public key to be used for authentication.
  Currently use terra.pub for this entry.
  DESCRIPTION
  default = "terra.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair."
}

variable "aws_region" {
  description = <<DESCRIPTION
  AWS region to launch servers.  This will be provided
  in the Deployment Template Spreadsheet.
  Examples:
      us-west-2
      us-east-1
  DESCRIPTION
}

variable "appinstance_type"{
  description = <<DESCRIPTION
  APP Instance size: Use size specificied in design document.
  Typically t3.large for all environments.  You must enter
  a value here even in a single server deployment.  This will
  be provided in the Deployment Template Spreadsheet.
  Enter:
      t3.large
   DESCRIPTION
}

variable "app_instance_count" {
  description = <<DESCRIPTION
  Number of App Instances to be provisioned.  In a single server
  deployment you will enter a 0 here.
  DESCRIPTION
}

variable "customer_name" {
  description = <<DESCRIPTION
  Name of customer server.  This will be provided in the Deployment
  Template Spreadsheet. Note this should be one word no spaces.
  DESCRIPTION
}

variable "envrionment" {
  description = <<DESCRIPTION
  Name of the Environment(PROD, DR, STG, UAT, DEV, TST).  This will be provided in the Deployment
  Template Spreadsheet.
  DESCRIPTION
}

variable "app_role" {
  description = <<DESCRIPTION
  Name of the App server role(APP, RDP).  This will be provided in the Deployment
  Template Spreadsheet.
  DESCRIPTION
}

variable "cidr_block" {
  description = <<DESCRIPTION
  Next /27 cidr to be used.  This will be provided in the Deployment
  Template Spreadsheet.
  DESCRIPTION
}

variable "zone_id" {
  description = "Provide the Zone ID in Route 53 Use Z272VSMY1S2MLD for Terraform Prod Env"
  default = "Z272VSMY1S2MLD"
}

variable "record_set_name" {
  description = <<DESCRIPTION
  Provide the DNS Short Name, this is found in the Customer Build Doc on the DNS tab i.e. NA-9999-100-R
  DESCRIPTION
}

variable "record_type" {
  description = "Provide the DNS record type A or CNAME, always choose CNAME unless directed otherwise."
  default = "CNAME"
}

variable "app_computer_name" {
  description = <<DESCRIPTION
  Provide the name of the App computer minus the number that will be used in Active Directory i.e. SHO-AVATRAPVP
  This is found in the Customer Build Doc
  DESCRIPTION
}

variable "client_ou" {
  description = <<DESCRIPTION
  Enter the OU location for the server in Active Directory
  This typically the name of the Client i.e. "PiedPiper" without spaces
  You must create the OU first before running this script.
  This will be under wocloud.com -> Clients ->
  DESCRIPTION
}

variable "backup_state" {
  description = "Enables backup of all volumes via an AMI"
  default = "Yes"
}

########################################################
# Updated for WOProgram with RDS
########################################################
variable "rds_storage" {
  description = "Provided the amount of storage to allocate to Oracle"
  default = 60
}

variable "rds_user" {
  description = "Provided the master user name for the database"
  default = "womaster"
}

variable "rds_instance" {
  description = "Provided the instance class for the database"
  default = "db.m5.large"
}

variable "rds_backup_retention" {
  description = "Provided the backup retention period for the database"
  default = 7
}
variable "rds_backup_window" {
  description = "Provided the backup window for the database"
  default = "03:00-06:00"
}

variable "rds_maintenance_window" {
  description = "Provided the maintenance window for the database"
  default = "Sun:06:00-Sun:09:00"
}

variable "rds_storage_type" {
  description = "Provided the storage type for the database"
  default = "gp2"
}

variable "rds_engine" {
  description = "Provided the oracle engine for the database"
  default = "oracle-se2"
}

variable "rds_engine_vers" {
  description = "Provided the oracle engine version for the database"
  default = "12.2.0.1.ru-2019-01.rur-2019-01.r1"
}

variable "rds_role_arn" {
  description = "The ARN of the IAM Role that allows for RDS and S3 integration"
  default = "arn:aws:iam::384972204486:role/allowrdsforwo-odbtransfer"
}

variable "nlb_listener_port" {
  description = "Provide the TCP port for the NLB listener"
  default     = "443"
}

variable "rds_db_name" {
  description = <<DESCRIPTION
  DB Instance Name should be 8 characters or less and
  convey customer and environment information.
  For example:
	NATGDEV
  DESCRIPTION
}

variable "rds_db_password" {
  description = <<DESCRIPTION
  Please provide a complex password for the RDS WOMaster Account
  DESCRIPTION
}

variable "rds_param_group" {
  description = <<DESCRIPTION
  Please provide the parameter group name here:
  DESCRIPTION
  default = "woprogram-oracle-se2-12-2"
}

variable "rds_option_group" {
  description = <<DESCRIPTION
  Please provide the option group name here:
  DESCRIPTION
  default = "woprogram-oracle-se2-12-2"
}

variable "rds_az_subnet_id" {
  type = "map"
  default = {
    "us-east-1" = "subnet-09296d1c8db377d94"
    "us-west-2" = "subnet-038f87a11dc2242a5"
  }
}

########################################################

########################################################
# Variables mapped by AMI
########################################################

variable "ami_type" {
   description = <<DESCRIPTION
   Choose which AMI type for the Database server to use
   Windows 2016 Base(ISV), Windows 2016 SQL 2016 Std(Pay as you go), 
   Windows 2016 SQL 2016 ENT(Pay as you go), or Windows 2016 SQL 2016 Web(Pay as you go)
   Choices:
       win2016_base_ami
       win2016_sql_2016_std_ami
       win2016_sql_2016_ent_ami
       win2016_sql_2016_web_ami
   DESCRIPTION
}

# Windows 2016 DB AMI's variable mapped by Region
variable "win2016_amis" {
    default = {
          "win2016_base_ami.us-east-1" = "ami-0e9fd09d5025defc0"
          "win2016_sql_2016_std_ami.us-east-1" = "ami-0d8e9d3c98293e5c6"
          "win2016_sql_2016_ent_ami.us-east-1" = "ami-0ed8c66c2e04cdc22"
          "win2016_sql_2016_web_ami.us-east-1" = "ami-0e785c70baa4b36d0"          
          "win2016_base_ami.us-west-2" = "ami-0e08268579e380cac"
          "win2016_sql_2016_std_ami.us-west-2" = "ami-08836d43d1d19e924"
          "win2016_sql_2016_ent_ami.us-west-2" = "ami-0a2182ef8c7d99a4a"
          "win2016_sql_2016_web_ami.us-west-2" = "ami-0ba06715161174264"
           }
}

# App AMI variable mapped by Region
variable "win2016_app_amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-0e9fd09d5025defc0"
    "us-west-2" = "ami-0e08268579e380cac"
  }
}

########################################################
# Variables mapped by Region
########################################################

# VPC variable mapped by Region
variable "vpc" {
  type = "map"
  default = {
    "us-east-1" = "vpc-efa07f88"
    "us-west-2" = "vpc-5766bd33"
  }
}

# Availability Zone variable mapped by Region
variable "avail_zone" {
  type = "map"
  default = {
    "us-east-1" = ["us-east-1b", "us-east-1a", "us-east-1d"]
    "us-west-2" = ["us-west-2b", "us-west-2a", "us-west-2d"]
  }
}

# Route Table variable mapped by Region
variable "rtb" {
  type = "map"
  default = {
    "us-east-1" = "rtb-9cb651e1"
    "us-west-2" = "rtb-47722c23"
  }
}

# VPC Security Group assigned to variable sg1
variable "sg1" {
	type = "map"
	default = {
		"us-east-1" = "sg-f09de58a"
		"us-west-2" = "sg-10589576"
	}
}

# VPC Security Group assigned to variable sg2
variable "sg2" {
	type = "map"
	default = {
		"us-east-1" = "sg-1828af63"
		"us-west-2" = "sg-182c9e7e"
	}
}

# VPC Security Group assigned to variable sg3
variable "sg3" {
	type = "map"
	default = {
		"us-east-1" = "sg-b64f7ccc"
		"us-west-2" = "sg-8f2795e9"
	}
} 

# Time Zone variable mapped by Region
variable "time_zone" {
  type = "map"
  default = {
    "us-east-1" = "Eastern Standard Time"
    "us-west-2" = "Pacific Standard Time"
  }
}
