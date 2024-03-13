provider "aws" {
  region = "your_aws_region"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "your_az"
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "your_az"
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "your_second_az"
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "your_second_az"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_eip" "nat_eip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "BastionHostSG"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group" "web_sg" {
  name        = "WebServerSG"
  description = "Security group for web server"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group" "app_sg" {
  name        = "AppServerSG"
  description = "Security group for app server"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group" "db_sg" {
  name        = "DBServerSG"
  description = "Security group for database server"
  vpc_id      = aws_vpc.my_vpc.id
}

# Define rules for security groups
# You can define ingress and egress rules here

# Now define instances for Bastion Host, Web Server, App Server, and Database Server
