provider "aws" {
  region = "us-west-2"
}
#Creates a VPC that is the base of my project
resource "aws_vpc" "project-3tier-vpc" {
    cidr_block = "10.0.0.0/16"
    region = "us-east-1"
    
    tags = {
        name = "project-3tier-vpc"
    }
}
#Creates 1 public subnet for the "web tier" in 2 AZ's 
resource "aws_subnet" "Public_Subnet_Web" {
  vpc_id = aws_vpc.project-3tier-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = ["us-east-1a", " us-east-1b"]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public_Subnet_Web"
  }
}
#Creates 1 private subnet for the "app tier" in 2 AZ's 
resource "aws_subnet" "Private_Subnet_App" {
  vpc_id = aws_vpc.project-3tier-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = ["us-east-1a", " us-east-1b"]
  map_public_ip_on_launch = false
  tags = {
    Name = "Private_Subnet_App"

  }
}
#Creates 1 private subnet for the "app tier" in 2 AZ's 
resource "aws_subnet" "Private_Subnet_DB" {
  vpc_id = aws_vpc.project-3tier-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = ["us-east-1a", " us-east-1b"]
  map_public_ip_on_launch = false 
  tags = {
    name = "Private_Subnet_DB"
  }
}
#Creates an IGW to route traffic from the internet 
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.project-3tier-vpc

  tags = {
    Name = "IGW"
  }
}