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
#Creates a Elastic IP
resource "aws_eip" "Elastic_IP" {
    domain = aws_vpc.project-3tier-vpc

    tags = {
      Name = "Elastic_IP"
    }
  
}
#Creates NAT Gateway for private subnets to reach internet
resource "aws_nat_gateway" "name" {
    allocation_id = aws_eip.Elastic_IP.id
    subnet_id = aws_subnet.Public_Subnet_Web.id

    tags = {
      Name = "NAT_Gateway"
    }
}
#Creates Security Groups for  each tier
resource "aws_security_group" "Web_Security_Group" {
    name = "Web_Security_Group" 
    description = "Security Group for Web Tier"
    vpc_id = aws_vpc.project-3tier-vpc.id

    tags = {
        Name = "Web_Security_Group"
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress { 
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


  
}
resource "aws_security_group" "App_Security_Group" {
    name = "App_Security_Group" 
    description = "Security Group for App Tier"
    vpc_id = aws_vpc.project-3tier-vpc.id

    tags = {
        Name = "App_Security_Group"
    }
    ingress {
        description = "Web SG Inbound"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        security_groups = [aws_security_group.Web_Security_Group.id]
    
    }
    egress { 
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        security_groups = [aws_security_group.DB_Security_Group.id]
    }

  
}
resource "aws_security_group" "DB_Security_Group" {
    name = "DB_Security_Group" 
    description = "Security Group for DB Tier"
    vpc_id = aws_vpc.project-3tier-vpc.id

    tags = {
        Name = "DB_Security_Group"
    }
    ingress {
        description = "App SG Inbound"
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        security_groups = [aws_security_group.App_Security_Group.id]
    
    }
    ingress { 
        description = "MySQL Inbound"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        security_groups = [aws_security_group.App_Security_Group.id]
    }
    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

  
}
  
