# Provider block specifies the AWS region to operate in
provider "aws" {
  region = "us-west-2" // Specifies the AWS region to operate in
}

# Resource block for creating the VPC
resource "aws_vpc" "three_tier_vpc" {
  cidr_block = "192.168.0.0/16" // Defines the CIDR block for the VPC
  id         = "aws_vpc.main.id" // Assigns a custom ID for the VPC (not recommended to use)
}

# Resource block for creating the public subnet for web and bastion instances
resource "aws_subnet" "pub_web_bastion" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.1.0/24"  // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
  map_public_ip_on_launch = true // Indicates whether instances launched in this subnet should be assigned a public IP address automatically
}

# Resource block for creating the private subnets for application servers
resource "aws_subnet" "priv_appserver" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.2.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
}

# Resource block for creating the private subnet for primary database instances
resource "aws_subnet" "priv_db_primary" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.3.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
}

# Resource block for creating the private subnet for secondary database instances in another AZ
resource "aws_subnet" "priv_db_secondary-az2" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.4.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2b" // Specifies the availability zone for the subnet
}

# Resource block for allocating an Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc" // Indicates that the Elastic IP is associated with a VPC
}

# Resource block for creating a NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id // Specifies the allocation ID of the Elastic IP for the NAT Gateway
  subnet_id     = aws_subnet.pub_web_bastion.id // Specifies the subnet ID where the NAT Gateway is deployed
}

# Resource block for creating an Internet Gateway
resource "aws_internet_gateway" "igw" {
  // Specifies the VPC ID to attach the Internet Gateway to
  vpc_id = aws_vpc.three_tier_vpc.id 
}

# Resource block for attaching the Internet Gateway to the VPC
resource "aws_vpc_gateway_attachment" "vpc_gw_attach" {
  vpc_id         = aws_vpc.three_tier_vpc.id // Specifies the VPC ID to attach the Internet Gateway to
  internet_gateway_id = aws_internet_gateway.igw.id // Specifies the Internet Gateway ID to attach to the VPC
}

# Create a route table for the public subnet and associate it with the subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.three_tier_vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.pub_web_bastion.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a route table for the private subnets and associate it with the subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.three_tier_vpc.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "192.168.0.0/16"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.priv_appserver.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.priv_db_primary.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_3" {
  subnet_id      = aws_subnet.priv_db_secondary-az2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Resource block for creating the security group for the Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for the Bastion Host"

  vpc_id = aws_vpc.three_tier_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource block for creating the security group for the web server
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for the web server"

  vpc_id = aws_vpc.three_tier_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource block for creating the security group for the app server
resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Security group for the app server"

  vpc_id = aws_vpc.three_tier_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource block for creating the security group for the database
resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Security group for the database"

  vpc_id = aws_vpc.three_tier_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add rules to security groups to link them together
resource "aws_security_group_rule" "bastion_to_web_server" {
  security_group_id        = aws_security_group.bastion_sg.id
  source_security_group_id = aws_security_group.web_server_sg.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "web_server_to_app_server" {
  security_group_id        = aws_security_group.web_server_sg.id
  source_security_group_id = aws_security_group.app_server_sg.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "app_server_to_database" {
  security_group_id        = aws_security_group.app_server_sg.id
  source_security_group_id = aws_security_group.database_sg.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
}

# Resource block for creating the Bastion Host
resource "aws_instance" "bastion_host" {
  ami           = "ami-12345678" // Replace with the appropriate Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_web_bastion.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
}

# Resource block for creating the web server EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-12345678" // Replace with the appropriate Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_web_bastion.id
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    EOF
}

# Resource block for creating the app server EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-12345678" // Replace with the appropriate Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_web_bastion.id
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y mariadb-server
    sudo service mariadb start
    EOF
}

# Resource block for creating the DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.priv_db_primary.id, aws_subnet.priv_db_secondary-az2.id]
}

# Resource block for creating the DB instance
resource "aws_db_instance" "db_instance" {
  identifier             = "my-db-instance"
  engine                 = "mariadb"
  engine_version         = "10.4"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible   = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period = 0
  storage_encrypted      = false
  username               = "root"
  password               = "Re:Start!9"
  name                   = "mydb"
}

