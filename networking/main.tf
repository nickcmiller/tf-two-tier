
#Generates a list of AZs called available
data "aws_availability_zones" "available" {}
#Creates a list the the length var.max_subnets of the available AZs
resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}


#Generate a random integer to make unique resource names
resource "random_integer" "random" {
  min = 1
  max = 100
}

#Create a VPC using the CIDR passed from a variable in root
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  #Using the random integer to name the VPC
  tags = {
    Name = "my_vpc-${random_integer.random.id}"
  }

  #Ensure the VPC will always be replaced before its destroyed as many other resources will be dependent on it
  lifecycle {
    create_before_destroy = true
  }
}

#Creates two public subnets
resource "aws_subnet" "public_subnet" {
  #Determines number of subnets to create
  count  = var.public_sn_count
  vpc_id = aws_vpc.my_vpc.id
  #pulls a cidr from the public_cidrs list defined in root
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true

  #Deposits subnet in one of the available AZs
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "public_${count.index + 1}"
  }
}

#Creates two private subnets for web tier
resource "aws_subnet" "web_subnet" {
  #Determines number of subnets to create
  count  = var.web_sn_count
  vpc_id = aws_vpc.my_vpc.id
  #pulls a cidr from the public_cidrs list defined in root
  cidr_block = var.web_cidrs[count.index]

  #Deposits subnet in one of the available AZs
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "web_${count.index + 1}"
  }
}

#Creates two private subnets for web tier
resource "aws_subnet" "rds_subnet" {
  #Determines number of subnets to create
  count  = var.rds_sn_count
  vpc_id = aws_vpc.my_vpc.id
  #pulls a cidr from the public_cidrs list defined in root
  cidr_block = var.rds_cidrs[count.index]

  #Deposits subnet in one of the available AZs
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "rds_${count.index + 1}"
  }
}

#Create a default route table
#The private subnets will have default access to the default_route_table
resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id
  tags = {
    Name = "my_default_rt"
  }
}

#Add route table for traffic to the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_public_rt"
  }
}

#Associate both public subnets with the public route table
resource "aws_route_table_association" "public_rt_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

#Add Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}

#Create a public route that allows all traffic to the IGW
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway, aws_eip.nat_eip]
}

resource "aws_route" "default_route_to_nat" {
  route_table_id         = aws_default_route_table.default_route_table.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_nat_gateway.nat_gateway]
}