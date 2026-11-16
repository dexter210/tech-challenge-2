# Find available Availability Zones in the selected AWS Region.
data "aws_availability_zones" "available" {
  state = "available"
}

# Create the project's network.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tech-challenge-2-vpc"
  }
}

# Create two public subnets in different Availability Zones.
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "tech-challenge-2-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

# Attach an internet gateway to the VPC.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tech-challenge-2-igw"
  }
}

# Give the public subnets a route to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "tech-challenge-2-public-rt"
  }
}

# Associate each public subnet with the public route table.
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}