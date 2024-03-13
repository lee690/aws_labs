provider "aws" {
  region = "us-west-2"
}
resource "aws_vpc" "3_tier_vpc" {
  cidr_block = "192.168.0.0/16"
  id         = "aws_vpc.main.id"
}

resource "aws_subnet" "pub_web_bastion" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"  
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "priv_appserver" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "priv_db_primary" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "priv_db_secondary-az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.4.0/24"
  availability_zone = "us-west-2b"
}
