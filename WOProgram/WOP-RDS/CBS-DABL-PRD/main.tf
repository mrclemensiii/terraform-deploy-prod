provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "WideOrbit"

    workspaces {
      name = "CBS-DABL-PRD"
    }
  }
}

##################################################
# Import Public Key into EC2 Instance for Access
##################################################
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}
##################################################


##################################################
# Create a subnet to launch our instances into
##################################################

resource "aws_subnet" "default" {
  vpc_id                  = "${lookup(var.vpc, var.aws_region)}"
  cidr_block              = "${var.cidr_block}"
  availability_zone	  = "${element(var.avail_zone[var.aws_region],count.index)}"
  map_public_ip_on_launch = true
tags {
    Name = "${var.customer_name}"
  }

}
##################################################


##################################################
# Our default security group to access
# the instances over SSH and HTTP
##################################################
resource "aws_security_group" "default" {
  name        = "${var.customer_name}-${var.envrionment}"
  description = "${var.customer_name}"
  vpc_id      = "${lookup(var.vpc, var.aws_region)}"

tags {
	Name = "${var.customer_name}"
    }

  ingress {
    from_port   = "${var.nlb_listener_port}"
    to_port     = "${var.nlb_listener_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
##################################################


##################################################
# Configure Elastic IP for APP Server
##################################################
resource "aws_eip" "Wideorbit-AppEIP" {
  count = "${var.app_instance_count}"
  instance = "${element(aws_instance.Wideorbit-App.*.id, count.index)}"
}
##################################################


##################################################
# Application Instance Creation
##################################################
resource "aws_instance" "Wideorbit-App" {
  iam_instance_profile = "WOCLOUD-MGMT"
  count = "${var.app_instance_count}"
  connection {
    # The default username for our AMI
    user = "wideorbit"
  }

  tags {
    Name = "${var.app_computer_name}0${count.index}"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
    Role = "${var.app_role}"
    AmiBackUp = "${var.backup_state}"
    AMI_Type = "win2016_base_ami"
  }

  instance_type = "${var.appinstance_type}"
  ami = "${lookup(var.win2016_app_amis, var.aws_region)}"

 volume_tags { 
	Name = "${var.app_computer_name}0${count.index}"
    }

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 50
  }

  # The name of our keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security groups
  vpc_security_group_ids = ["${aws_security_group.default.id}","${lookup(var.sg1, var.aws_region)}","${lookup(var.sg2, var.aws_region)}","${lookup(var.sg3, var.aws_region)}"]

  subnet_id = "${aws_subnet.default.id}"

  user_data = <<EOF
<powershell>
Get-Disk | ?{$_.number -ne 0}| Set-Disk -IsOffline $False
Get-Disk | ?{$_.number -ne 0}| Set-Disk -isReadOnly $False
Get-Disk | ?{$_.number -ne 0}| Initialize-Disk -PartitionStyle GPT
New-Partition -DiskNumber 1 -DriveLetter D -UseMaximumSize
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel Data
Set-TimeZone -Name "${lookup(var.time_zone, var.aws_region)}"
$username = "wocloud\woprovdomainjoinsvc"
$pwdTxt = "76492d1116743f0423413b16050a5345MgB8AGUANgBwAEUAbABkAHgARgBMAFkAdwBLAGsAVwArAGkALwAzADEASwArAEEAPQA9AHwANgAxADMANgA0ADIAMwA2ADcAZgBkADIAMAA4ADAAMQA0ADkANQA0ADQAOAAwADIANQAzADYAZABkAGUANgA4ADIAZQAwADEAYQA1ADYAMQBkADgAZAA1ADUANwBiADgANwA0ADkANwA0ADMAMgBlADgAZAAyAGQANABhADMAZgBhADEAYwA4ADYAMQBkADQAMAA5AGIAMABjAGMANgA3AGIAMwA2ADIAMgAwAGYANABlAGIAZgBhAGEANgBiADcA"
[Byte[]] $key = (1..16)
$securePwd = $pwdTxt | ConvertTo-SecureString -Key $key
$credential = New-Object System.Management.Automation.PSCredential($username,$securePwd)
Add-Computer -domainname wocloud.com -OUPath "OU=${var.client_ou},OU=Clients,DC=wocloud,DC=com" -NewName "${var.app_computer_name}0${count.index}" -Credential $credential -Force -Restart
</powershell>
EOF
}
##################################################


##################################################
# Associate Route Table to new Subnet
##################################################
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.default.id}"
  route_table_id = "${lookup(var.rtb, var.aws_region)}"
}
########################################################


########################################################
# Setup Network Load Balancer for One Server Deployments
########################################################
# Create a new Network Load Balancer
resource "aws_lb" "nlb" {
  name  = "${var.customer_name}-NLB-${var.envrionment}"
  load_balancer_type = "network"
  internal = false
  subnets = ["${aws_subnet.default.id}"]

  enable_deletion_protection = false

   tags {
    Name = "${var.customer_name}-nlb"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
  }
}

# Create a new Target Group
resource "aws_lb_target_group" "nlb" {
  name = "${var.customer_name}-TG-${var.envrionment}"
  port = "${var.nlb_listener_port}"
  protocol = "TCP"
  vpc_id = "${lookup(var.vpc, var.aws_region)}"
 
   tags {
    Name = "${var.customer_name}-tg"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
  }
}

# Create NLB Listener
resource "aws_lb_listener" "nlb" {
  load_balancer_arn = "${aws_lb.nlb.arn}"
  port = "${var.nlb_listener_port}"
  protocol = "TCP"
default_action {
    target_group_arn = "${aws_lb_target_group.nlb.arn}"
    type = "forward"
  }
}

resource "aws_lb_target_group_attachment" "nlb_app_target" {
  # count = "${var.applb}"
   target_group_arn = "${aws_lb_target_group.nlb.arn}"
  # define multiple targets like this?
  # target_id = "${aws_instance.Wideorbit-App.id}"
  target_id = "${element(aws_instance.Wideorbit-App.*.id, count.index)}"
  #target_id = "${var.XXXX-appserver2}"
  # or as a list?
  # target_id = ["${var.XXXX-appserver1}", "${var.XXXX-appserver2}"]
  #target_id = ["${aws_instance.Wideorbit-DB.id}", "${element(aws_instance.Wideorbit-App.*.id, count.index)}"]

  port = "${var.nlb_listener_port}"
  }

##################################################

##################################################
# Create RDS Security Group
##################################################
resource "aws_security_group" "rds" {
  vpc_id = "${lookup(var.vpc, var.aws_region)}"
  name = "${var.customer_name}-${var.envrionment}-RDS-Access"
  description = "${var.customer_name}"
  tags = {Name = "${var.customer_name}"}
  
  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
##################################################

##################################################
# Create RDS Subnet Group
##################################################
resource "aws_db_subnet_group" "default" {
  name = "${lower(var.customer_name)}-${lower(var.envrionment)}-subnet-group"
  subnet_ids = ["${lookup(var.rds_az_subnet_id, var.aws_region)}","${aws_subnet.default.id}"]
  tags = {Name = "${var.customer_name}"}
}
##################################################

##################################################
# Create RDS Database Instance
##################################################
resource "aws_db_instance" "default" {
  name = "${var.rds_db_name}"
  identifier = "${lower(var.customer_name)}-${lower(var.envrionment)}"
  tags = {Name = "${var.customer_name}"}
  
  allocated_storage = 100
  auto_minor_version_upgrade = "false"
  backup_retention_period = 7
  backup_window = "03:00-06:00"
  copy_tags_to_snapshot = "true"
  availability_zone = "${aws_subnet.default.availability_zone}"
  maintenance_window = "Sun:06:00-Sun:09:00"
  license_model = "license-included"
  storage_type = "gp2"
  engine = "oracle-se2"
  engine_version = "12.2.0.1.ru-2019-01.rur-2019-01.r1"
  instance_class = "db.m5.large"
  username = "womaster"
  password = "${var.rds_db_password}"
  parameter_group_name = "${var.rds_param_group}"
  option_group_name = "${var.rds_option_group}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  apply_immediately = "true"
  
  ################################################
  # only used in Dev for testing to allow for quick destroy
  skip_final_snapshot = "true"
  deletion_protection = "false"
  ################################################
  
}
##################################################

##################################################
# Create RDS Database Instance Role Association
##################################################
resource "aws_db_instance_role_association" "default" {
  db_instance_identifier = "${aws_db_instance.default.id}"
  feature_name           = "S3_INTEGRATION"
  role_arn               = "arn:aws:iam::384972204486:role/allowrdsforwo-odbtransfer"
}
##################################################


##################################################
# Create Record in Route 53
##################################################
resource "aws_route53_record" "woexchange" {
  zone_id = "${var.zone_id}"
  name = "${var.record_set_name}"
  type = "${var.record_type}"
  ttl = "300"
  records = ["${aws_lb.nlb.dns_name}"]
}
##################################################