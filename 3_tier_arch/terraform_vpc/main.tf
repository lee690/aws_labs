provider "aws" {
  region = "us-west-2" // Specifies the AWS region to operate in
}

resource "aws_vpc" "3_tier_vpc" {
  cidr_block = "192.168.0.0/16" // Defines the CIDR block for the VPC
  id         = "aws_vpc.main.id" // Assigns a custom ID for the VPC (not recommended to use)
}

resource "aws_subnet" "pub_web_bastion" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.1.0/24"  // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
  map_public_ip_on_launch = true // Indicates whether instances launched in this subnet should be assigned a public IP address automatically
}

resource "aws_subnet" "priv_appserver" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.2.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
}

resource "aws_subnet" "priv_db_primary" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.3.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2a" // Specifies the availability zone for the subnet
}

resource "aws_subnet" "priv_db_secondary-az2" {
  vpc_id            = aws_vpc.main.id // Specifies the VPC ID to associate the subnet with
  cidr_block        = "192.168.4.0/24" // Defines the CIDR block for the subnet
  availability_zone = "us-west-2b" // Specifies the availability zone for the subnet
}

resource "aws_eip" "nat_eip" {
  vpc = true // Indicates that the Elastic IP is associated with a VPC
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id // Specifies the allocation ID of the Elastic IP for the NAT Gateway
  subnet_id     = aws_subnet.pub_web_bastion.id // Specifies the subnet ID where the NAT Gateway is deployed
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.3_tier_vpc.id // Specifies the VPC ID to attach the Internet Gateway to
}

resource "aws_vpc_gateway_attachment" "vpc_gw_attach" {
  vpc_id         = aws_vpc.3_tier_vpc.id // Specifies the VPC ID to attach the Internet Gateway to
  internet_gateway_id = aws_internet_gateway.igw.id // Specifies the Internet Gateway ID to attach to the VPC
}
