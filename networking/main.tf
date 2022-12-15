
#Generates a list of AZs called available
data "aws_availability_zones" "available"{}
#Creates a list the the length var.max_subnets of the available AZs
resource "random_shuffle" "az_list"{
    input = data.aws_availability_zones.available.names
    result_count = var.max_subnets
}


#Generate a random integer to make unique resource names
resource "random_integer" "random"{
    min = 1
    max = 100
}

#Create a VPC using the CIDR passed from a variable in root
resource "aws_vpc" "my_vpc"{
    cidr_block=var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    
    #Using the random integer to name the VPC
    tags = {
        Name = "my_vpc-${random_integer.random.id}"
    }
    
    #Ensure the VPC will always be replaced before its destroyed as many other resources will be dependent on it
    lifecycle{
        create_before_destroy = true
    }
}

#Creates two public subnets
resource "aws_subnet" "public_subnet" {
    #Determines number of subnets to create
    count = var.public_sn_count
    vpc_id = aws_vpc.my_vpc.id
    #pulls a cidr from the public_cidrs list defined in root
    cidr_block = var.public_cidrs[count.index]
    map_public_ip_on_launch = true
    
    #Deposits subnet in one of the available AZs
    availability_zone = random_shuffle.az_list.result[count.index]
    
    tags = {
        Name = "public_${count.index+1}"
    }
}

