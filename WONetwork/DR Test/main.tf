provider "aws" {
  region = "${var.aws_region}"
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
# Create a Production subnet to launch our 
# instances into
##################################################

resource "aws_subnet" "default" {
  vpc_id  = "${lookup(var.vpc, var.aws_region)}"
  cidr_block = "${var.cidr_block}"
  availability_zone = "${element(var.avail_zone[var.aws_region],count.index)}"
  map_public_ip_on_launch = true
tags {
    Name = "${var.customer_name}"
  }

}
##################################################


##################################################
# Create a DR subnet to launch our instances into
##################################################

resource "aws_subnet" "dr" {
  count = "${var.dr}"
  vpc_id = "${lookup(var.vpc, var.aws_region)}"
  cidr_block = "${var.dr_cidr_block}"
  availability_zone = "${lookup(var.dr_avail_zone, var.aws_region)}"
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
    from_port               = "${var.sg_from_port}"
    to_port                 = "${var.sg_to_port}"
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
# Database Instance Creation
##################################################
resource "aws_instance" "Wideorbit-DB" {
  iam_instance_profile = "WOCLOUD-MGMT"  
  count = "${var.db_instance_count}"
  connection {
    # The default username for our AMI
    user = "wideorbit"
  }

 tags {
    Name = "${upper(var.db_computer_name)}0${count.index}"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
    Role = "${var.db_role}"
    AmiBackUp = "${var.backup_state}"
    AMI_Type = "${var.ami_type}"
  }

  instance_type = "${var.dbinstance_type}"
  ami = "${lookup(var.win2016_amis, "${var.ami_type}.${var.aws_region}")}"

 volume_tags { 
	Name = "${upper(var.db_computer_name)}0${count.index}"
    }

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
    delete_on_termination = "true"
       
  }
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "128"
    
  }
 ebs_block_device {
    device_name = "/dev/xvdc"
    volume_type = "gp2"
    volume_size = "384"
    
  }
 ebs_block_device {
    device_name = "/dev/xvdd"
    volume_type = "gp2"
    volume_size = "64"
    
  }
 ebs_block_device {
    device_name = "/dev/xvde"
    volume_type = "io1"
    volume_size = "128"
    iops = "500"
    
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
New-Partition -DiskNumber 2 -DriveLetter E -UseMaximumSize
New-Partition -DiskNumber 3 -DriveLetter L -UseMaximumSize
New-Partition -DiskNumber 4 -DriveLetter T -UseMaximumSize
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel Data -AllocationUnitSize 64KB
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel Backup -AllocationUnitSize 64KB
Format-Volume -DriveLetter L -FileSystem NTFS -NewFileSystemLabel Log -AllocationUnitSize 64KB
Format-Volume -DriveLetter T -FileSystem NTFS -NewFileSystemLabel TempDB -AllocationUnitSize 64KB
Set-TimeZone -Name "${lookup(var.time_zone, var.aws_region)}"
$username = "wocloud\woprovdomainjoinsvc"
$pwdTxt = "76492d1116743f0423413b16050a5345MgB8AGUANgBwAEUAbABkAHgARgBMAFkAdwBLAGsAVwArAGkALwAzADEASwArAEEAPQA9AHwANgAxADMANgA0ADIAMwA2ADcAZgBkADIAMAA4ADAAMQA0ADkANQA0ADQAOAAwADIANQAzADYAZABkAGUANgA4ADIAZQAwADEAYQA1ADYAMQBkADgAZAA1ADUANwBiADgANwA0ADkANwA0ADMAMgBlADgAZAAyAGQANABhADMAZgBhADEAYwA4ADYAMQBkADQAMAA5AGIAMABjAGMANgA3AGIAMwA2ADIAMgAwAGYANABlAGIAZgBhAGEANgBiADcA"
[Byte[]] $key = (1..16)
$securePwd = $pwdTxt | ConvertTo-SecureString -Key $key
$credential = New-Object System.Management.Automation.PSCredential($username,$securePwd)
Add-Computer -domainname wocloud.com -OUPath "OU=${var.client_ou},OU=Clients,DC=wocloud,DC=com" -NewName "${upper(var.db_computer_name)}0${count.index}" -Credential $credential -Force -Restart
</powershell>
EOF
}
##################################################

##################################################
# DR Database Instance Creation
##################################################
resource "aws_instance" "Wideorbit-DB-DR" {
  iam_instance_profile = "WOCLOUD-MGMT"  
  count = "${var.dr ? var.db_instance_count : 0}"
  connection {
    # The default username for our AMI
    user = "wideorbit"
  }

 tags {
    Name = "${replace(upper(var.db_computer_name),"/.$/","R")}0${count.index}"
    Customer = "${var.customer_name}"
    Environment = "DR"
    Role = "${var.db_role}"
    AmiBackUp = "${var.backup_state}"
    AMI_Type = "${var.ami_type}"
  }

  instance_type = "${var.dbinstance_type}"
  ami = "${lookup(var.win2016_amis, "${var.ami_type}.${var.aws_region}")}"

 volume_tags { 
	Name = "${replace(upper(var.db_computer_name),"/.$/","R")}0${count.index}"
    }

  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
    delete_on_termination = "true"
       
  }
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "128"
    
  }
 ebs_block_device {
    device_name = "/dev/xvdc"
    volume_type = "gp2"
    volume_size = "384"
    
  }
 ebs_block_device {
    device_name = "/dev/xvdd"
    volume_type = "gp2"
    volume_size = "64"
    
  }
 ebs_block_device {
    device_name = "/dev/xvde"
    volume_type = "io1"
    volume_size = "128"
    iops = "500"
    
  }


  # The name of our keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security groups
  vpc_security_group_ids = ["${aws_security_group.default.id}","${lookup(var.sg1, var.aws_region)}","${lookup(var.sg2, var.aws_region)}","${lookup(var.sg3, var.aws_region)}"]

  subnet_id = "${aws_subnet.dr.id}"
  user_data = <<EOF
<powershell>
Get-Disk | ?{$_.number -ne 0}| Set-Disk -IsOffline $False
Get-Disk | ?{$_.number -ne 0}| Set-Disk -isReadOnly $False
Get-Disk | ?{$_.number -ne 0}| Initialize-Disk -PartitionStyle GPT
New-Partition -DiskNumber 1 -DriveLetter D -UseMaximumSize
New-Partition -DiskNumber 2 -DriveLetter E -UseMaximumSize
New-Partition -DiskNumber 3 -DriveLetter L -UseMaximumSize
New-Partition -DiskNumber 4 -DriveLetter T -UseMaximumSize
Format-Volume -DriveLetter D -FileSystem NTFS -NewFileSystemLabel Data -AllocationUnitSize 64KB
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel Backup -AllocationUnitSize 64KB
Format-Volume -DriveLetter L -FileSystem NTFS -NewFileSystemLabel Log -AllocationUnitSize 64KB
Format-Volume -DriveLetter T -FileSystem NTFS -NewFileSystemLabel TempDB -AllocationUnitSize 64KB
Set-TimeZone -Name "${lookup(var.time_zone, var.aws_region)}"
$username = "wocloud\woprovdomainjoinsvc"
$pwdTxt = "76492d1116743f0423413b16050a5345MgB8AGUANgBwAEUAbABkAHgARgBMAFkAdwBLAGsAVwArAGkALwAzADEASwArAEEAPQA9AHwANgAxADMANgA0ADIAMwA2ADcAZgBkADIAMAA4ADAAMQA0ADkANQA0ADQAOAAwADIANQAzADYAZABkAGUANgA4ADIAZQAwADEAYQA1ADYAMQBkADgAZAA1ADUANwBiADgANwA0ADkANwA0ADMAMgBlADgAZAAyAGQANABhADMAZgBhADEAYwA4ADYAMQBkADQAMAA5AGIAMABjAGMANgA3AGIAMwA2ADIAMgAwAGYANABlAGIAZgBhAGEANgBiADcA"
[Byte[]] $key = (1..16)
$securePwd = $pwdTxt | ConvertTo-SecureString -Key $key
$credential = New-Object System.Management.Automation.PSCredential($username,$securePwd)
Add-Computer -domainname wocloud.com -OUPath "OU=${var.client_ou},OU=Clients,DC=wocloud,DC=com" -NewName "${replace(upper(var.db_computer_name),"/.$/","R")}0${count.index}" -Credential $credential -Force -Restart
</powershell>
EOF
}
##################################################


##################################################
# Configure Elastic IP for DB Server
##################################################
resource "aws_eip" "Wideorbit-DBEIP" {
  count = "${var.db_instance_count}"
  instance = "${element(aws_instance.Wideorbit-DB.*.id, count.index)}"
}
##################################################

##################################################
# Configure Elastic IP for DR DB Server
##################################################
resource "aws_eip" "Wideorbit-DRDBEIP" {
  count = "${var.dr ? var.db_instance_count : 0}"
  instance = "${element(aws_instance.Wideorbit-DB-DR.*.id, count.index)}"
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
# Configure Elastic IP for DR APP Server
##################################################
resource "aws_eip" "Wideorbit-DRAppEIP" {
  count = "${var.dr ? var.app_instance_count : 0}"
  instance = "${element(aws_instance.Wideorbit-App-DR.*.id, count.index)}"
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
    Name = "${upper(var.app_computer_name)}0${count.index}"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
    Role = "${var.app_role}"
    AmiBackUp = "${var.backup_state}"
    AMI_Type = "win2016_base_ami"
  }

  instance_type = "${var.appinstance_type}"
  ami = "${lookup(var.win2016_app_amis, var.aws_region)}"

 volume_tags { 
	Name = "${upper(var.app_computer_name)}0${count.index}"
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
Add-Computer -domainname wocloud.com -OUPath "OU=${var.client_ou},OU=Clients,DC=wocloud,DC=com" -NewName "${upper(var.app_computer_name)}0${count.index}" -Credential $credential -Force -Restart
</powershell>
EOF
}
##################################################

##################################################
# DR Application Instance Creation
##################################################
resource "aws_instance" "Wideorbit-App-DR" {
  iam_instance_profile = "WOCLOUD-MGMT"
  count = "${var.dr ? var.app_instance_count : 0}"
  connection {
    # The default username for our AMI
    user = "wideorbit"
  }

  tags {
    Name = "${replace(upper(var.app_computer_name),"/.$/","R")}0${count.index}"
    Customer = "${var.customer_name}"
    Environment = "DR"
    Role = "${var.app_role}"
    AmiBackUp = "${var.backup_state}"
    AMI_Type = "win2016_base_ami"
  }

  instance_type = "${var.appinstance_type}"
  ami = "${lookup(var.win2016_app_amis, var.aws_region)}"

 volume_tags { 
	Name = "${replace(upper(var.app_computer_name),"/.$/","R")}0${count.index}"
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

  subnet_id = "${aws_subnet.dr.id}"

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
Add-Computer -domainname wocloud.com -OUPath "OU=${var.client_ou},OU=Clients,DC=wocloud,DC=com" -NewName "${replace(upper(var.app_computer_name),"/.$/","R")}0${count.index}" -Credential $credential -Force -Restart
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

##################################################
# Associate Route Table to new DR Subnet
##################################################
resource "aws_route_table_association" "dr" {
  count = "${var.dr}"
  subnet_id      = "${aws_subnet.dr.id}"
  route_table_id = "${lookup(var.rtb, var.aws_region)}"
}
########################################################


########################################################
# Setup Network Load Balancer for One Server Deployments
########################################################
# Create a new Network Load Balancer
resource "aws_lb" "nlbdb" {
  count = "${var.app_instance_count == 0 ? 1 : 0}"
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
resource "aws_lb_target_group" "nlbdb" {
  count = "${var.app_instance_count == 0 ? 1 : 0}"
  name = "${var.customer_name}-TG-${var.envrionment}"
  port = "9000"
  protocol = "TCP"
  vpc_id = "${lookup(var.vpc, var.aws_region)}"
 
   tags {
    Name = "${var.customer_name}-tg"
    Customer = "${var.customer_name}"
    Environment = "${var.envrionment}"
  }
}

# Create NLB Listener
resource "aws_lb_listener" "nlbdb" {
  count = "${var.app_instance_count == 0 ? 1 : 0}"
  load_balancer_arn = "${aws_lb.nlbdb.arn}"
  port = "${var.nlb_listener_port}"
  protocol = "TCP"
default_action {
    target_group_arn = "${aws_lb_target_group.nlbdb.arn}"
    type = "forward"
  }
}


resource "aws_lb_target_group_attachment" "nlb_db_target" {
  count = "${var.app_instance_count == 0 ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.nlbdb.arn}"
  target_id = "${aws_instance.Wideorbit-DB.id}"

  port = "${var.nlb_listener_port}"
  }
##################################################

########################################################
# Setup Network Load Balancer for Multi Server Deployments
########################################################
# Create a new Network Load Balancer
resource "aws_lb" "nlbapp" {
  count = "${var.app_instance_count > 0 ? 1 : 0}"
  name                      = "${var.customer_name}-NLB-${var.envrionment}"
  load_balancer_type        = "network"
  internal                  = false																	
  subnets                   = ["${aws_subnet.default.id}"]

  enable_deletion_protection = false

   tags {
    Name                    = "${var.customer_name}-nlb"
    Customer                = "${var.customer_name}"
    Environment             = "${var.envrionment}"
  }
}
# Create a new Target Group
resource "aws_lb_target_group" "nlbapp" {
  count                     = "${var.app_instance_count}"
  name                      = "${var.customer_name}-TG-${var.envrionment}-900${count.index}"
  port                      = "900${count.index}"
  protocol                  = "TCP"
  vpc_id                    = "${lookup(var.vpc, var.aws_region)}"
 
  tags {
    Name                    = "${var.customer_name}-tg"
    Customer                = "${var.customer_name}"
    Environment             = "${var.envrionment}"
  }
}

# Create NLB Listener
resource "aws_lb_listener" "nlbapp" {
  count                     = "${var.app_instance_count}"
  load_balancer_arn         = "${aws_lb.nlbapp.arn}"
  port                      = "900${count.index}"
  protocol                  = "TCP"
default_action {
    target_group_arn        = "${element(aws_lb_target_group.nlbapp.*.arn, count.index)}"
    type                    = "forward"
  }
}

resource "aws_lb_target_group_attachment" "nlb_app_target" {
  count                     = "${var.app_instance_count}"
  target_group_arn          = "${element(aws_lb_target_group.nlbapp.*.arn, count.index)}"
  target_id                 = "${element(aws_instance.Wideorbit-App.*.id, count.index)}"

  port                      = "900${count.index}"
  }
########################################################

##################################################
# Create Record in Route 53
##################################################
resource "aws_route53_record" "woexchangedb" {
  count                     = "${var.app_instance_count == 0 ? 1 : 0}"
  zone_id                   = "${var.zone_id}"
  name                      = "${var.record_set_name}"
  type                      = "${var.record_type}"
  ttl                       = "300"
  records                   = ["${aws_lb.nlbdb.dns_name}"]
}

resource "aws_route53_record" "woexchangeapp" {
  count                     = "${var.app_instance_count > 0 ? 1 : 0}"
  zone_id                   = "${var.zone_id}"
  name                      = "${var.record_set_name}"
  type                      = "${var.record_type}"
  ttl                       = "300"
  records                   = ["${aws_lb.nlbapp.dns_name}"]
}
##################################################

########################################################
# Setup DR Network Load Balancer for One Server Deployments
########################################################
# Create a new Network Load Balancer
resource "aws_lb" "nlbdbdr" {
  count = "${(var.dr > signum(var.app_instance_count)) ? 1 : 0}"
  name  = "${var.customer_name}-NLB-DR"
  load_balancer_type = "network"
  internal = false
  subnets = ["${aws_subnet.dr.id}"]

  enable_deletion_protection = false

   tags {
    Name = "${var.customer_name}-nlb"
    Customer = "${var.customer_name}"
    Environment = "DR"
  }
}

# Create a new Target Group
resource "aws_lb_target_group" "nlbdbdr" {
  count = "${(var.dr > signum(var.app_instance_count)) ? 1 : 0}"
  name = "${var.customer_name}-TG-DR"
  port = "9000"
  protocol = "TCP"
  vpc_id = "${lookup(var.vpc, var.aws_region)}"
 
   tags {
    Name = "${var.customer_name}-tg"
    Customer = "${var.customer_name}"
    Environment = "DR"
  }
}

# Create NLB Listener
resource "aws_lb_listener" "nlbdbdr" {
  count = "${(var.dr > signum(var.app_instance_count)) ? 1 : 0}"
  load_balancer_arn = "${aws_lb.nlbdbdr.arn}"
  port = "${var.nlb_listener_port}"
  protocol = "TCP"
default_action {
    target_group_arn = "${aws_lb_target_group.nlbdbdr.arn}"
    type = "forward"
  }
}


resource "aws_lb_target_group_attachment" "nlb_db_targetdr" {
  count = "${(var.dr > signum(var.app_instance_count)) ? 1 : 0}"
  target_group_arn = "${aws_lb_target_group.nlbdbdr.arn}"
  target_id = "${aws_instance.Wideorbit-DB-DR.id}"

  port = "${var.nlb_listener_port}"
  }
##################################################

########################################################
# Setup DR Network Load Balancer for Multi Server Deployments
########################################################
# Create a new Network Load Balancer
resource "aws_lb" "nlbappdr" {
  count = "${(signum(var.dr) * signum(var.app_instance_count)) == 1 ? 1 : 0}"
  name = "${var.customer_name}-NLB-DR"
  load_balancer_type = "network"
  internal = false																	
  subnets = ["${aws_subnet.dr.id}"]

  enable_deletion_protection = false

   tags {
    Name = "${var.customer_name}-nlb"
    Customer = "${var.customer_name}"
    Environment = "DR"
  }
}
# Create a new Target Group
resource "aws_lb_target_group" "nlbappdr" {
  count = "${var.dr ? var.app_instance_count : 0}"
  name                      = "${var.customer_name}-TG-DR-900${count.index}"
  port                      = "900${count.index}"
  protocol                  = "TCP"
  vpc_id                    = "${lookup(var.vpc, var.aws_region)}"
 
  tags {
    Name                    = "${var.customer_name}-tg"
    Customer                = "${var.customer_name}"
    Environment             = "DR"
  }
}

# Create NLB Listener
resource "aws_lb_listener" "nlbappdr" {
  count                     = "${var.dr ? var.app_instance_count : 0}"
  load_balancer_arn         = "${aws_lb.nlbappdr.arn}"
  port                      = "900${count.index}"
  protocol                  = "TCP"
default_action {
    target_group_arn        = "${element(aws_lb_target_group.nlbappdr.*.arn, count.index)}"
    type                    = "forward"
  }
}

resource "aws_lb_target_group_attachment" "nlb_app_targetdr" {
  count                     = "${var.dr ? var.app_instance_count : 0}"
  target_group_arn          = "${element(aws_lb_target_group.nlbappdr.*.arn, count.index)}"
  target_id                 = "${element(aws_instance.Wideorbit-App-DR.*.id, count.index)}"

  port                      = "900${count.index}"
  }
########################################################

##################################################
# Create DR Record in Route 53
##################################################
resource "aws_route53_record" "woexchangedbdr" {
  count = "${(var.dr > signum(var.app_instance_count)) ? 1 : 0}"
  zone_id = "${var.zone_id}"
  name = "${replace(var.record_set_name,"/.$/","r")}"
  type = "${var.record_type}"
  ttl = "300"
  records = ["${aws_lb.nlbdbdr.dns_name}"]
}

resource "aws_route53_record" "woexchangeappdr" {
  count  = "${(signum(var.dr) * signum(var.app_instance_count)) == 1 ? 1 : 0}"
  zone_id = "${var.zone_id}"
  name = "${replace(var.record_set_name,"/.$/","r")}"
  type = "${var.record_type}"
  ttl  = "300"
  records  = ["${aws_lb.nlbappdr.dns_name}"]
}
##################################################