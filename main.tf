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
#Creates 1 private subnet for the "DB tier" in 2 AZ's 
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
#Creates  Public Route Table
resource "aws_route_table" "Public_Subnet_Route_Table" {
  vpc_id = aws_vpc.project-3tier-vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id

  }
  tags = {
    Name = "Public_Subnet_Route_Table"
  }
}
#Associates Public RT with Public Subnet
resource "aws_route_table_association" "Public_Web" {
    subnet_id = aws_subnet.Public_Subnet_Web.id
    route_table_id = aws_route_table.Public_Subnet_Route_Table
}
#Creates Private Route Table for NAT GATAWAY
resource "aws_route_table" "Private_Subnet_Route_Table" {
  vpc_id = aws_vpc.project-3tier-vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.name.id

  }
  tags = {
    Name = "Private_Subnet_Route_Table"
  }
} 
#Associates App Private RT with Private Subnets
resource "aws_route_table_association" "Private_App" {
    subnet_id = aws_subnet.Private_Subnet_App
    route_table_id = aws_route_table.Private_Subnet_Route_Table
}
#Associates DB Private RT with Private Subnets
resource "aws_route_table_association" "Private_DB" {
    subnet_id = aws_subnet.Private_Subnet_DB
    route_table_id = aws_route_table.Private_Subnet_Route_Table
  
}
#Creates NAT Gateway for private subnets to reach internet
resource "aws_nat_gateway" "name" {
    allocation_id = aws_eip.Elastic_IP.id
    subnet_id = aws_subnet.Public_Subnet_Web.id

    tags = {
      Name = "NAT_Gateway"
    }
}
#Creates Web Security Group
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
#Creates App Security Group
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
#Creates DB Security Group
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
#Creates 1 EC2 instance for the web tier
resource "aws_instance" "Web" {
    ami = "ami-0abcdef1234567890"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.Web_Security_Group.id]
    subnet_id = aws_subnet.Public_Subnet_Web.id
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install apache2 -y
                systemctl start apache2
                systemctl enable apache2
                echo "It Works! from $(hostname -f)" > /var/www/html/index.html
                EOF
    tags = {
        Name = "Web"
    }
  
}
#Creates 1 MySQL DB instance for the DB
resource "aws_db_instance" "DB" {
    allocated_storage = 10
    db_name = "Private_DB"
    engine = "MySQL"
    engine_version = "8.0"
    username = data.aws_secretsmanager_secret_version.db_creds.secret_string["username"]
    password = data.aws_secretsmanager_secret_version.db_creds.secret_string["password"]
    instance_class = "db.t2.micro"
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = true

    tags = {
      name = "DB"
    }


}
#Create IAM Roles and Polices
resource "aws_iam_role" "ReadOnlyCloudWatchLogsandS3" {
    name = "ReadOnlyCloudWatchLogsandS3"
    assume_role_policy = jsondecode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    Service = "s3.amazonaws.com/*"
                    Service = "cloudwatch.amazonaws.com/*"
                }
            }
        ]

    })
    tags = {
        Name = "ReadOnlyCloudWatchLogsandS3"
    }
  
}
#Creats IAM Role policy 
resource "aws_iam_role_policy_attachment" "s3_readonly" {
    role = aws_iam_role.ReadOnlyCloudWatchLogsandS3.id
    policy_arn = "arn:aws:iam::policy/AmazonS3ReadOnlyAccess"
    policy_arn = "arn:aws:iam::policy/CloudWatchAgentServerPolicy"
    
    tags = {
        Name = "s3_readonly"
    }

  
}