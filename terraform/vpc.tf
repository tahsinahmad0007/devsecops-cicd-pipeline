# ==========================
# VPC Configuration
# ==========================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# ==========================
# Internet Gateway
# ==========================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# ==========================
# Public Subnets (Static AZs)
# ==========================
resource "aws_subnet" "public" {
  count = 2  # Create 2 subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = count.index == 0 ? "ap-south-1a" : "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}"
  }
}

# ==========================
# Private Subnets (Static AZs)
# ==========================
resource "aws_subnet" "private" {
  count = 2  # Create 2 subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = count.index == 0 ? "ap-south-1a" : "ap-south-1b"

  tags = {
    Name = "${var.app_name}-private-subnet-${count.index + 1}"
  }
}

# ==========================
# Public Route Table
# ==========================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

# ==========================
# Associate Public Subnets with Route Table
# ==========================
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
