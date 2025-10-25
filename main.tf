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
