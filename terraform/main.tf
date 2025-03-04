# Fetch existing VPCs
data "aws_vpcs" "existing_vpcs" {}

# Fetch existing subnets
data "aws_subnets" "existing_subnets" {
  count = length(data.aws_vpcs.existing_vpcs.ids) > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.existing_vpcs.ids[0]]
  }
}

# Fetch existing internet gateways
data "aws_internet_gateway" "existing_igws" {
  count = length(data.aws_vpcs.existing_vpcs.ids) > 0 ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpcs.existing_vpcs.ids[0]]
  }
}

# Determine VPC ID
locals {
  vpc_id = coalesce(
    try(data.aws_vpcs.existing_vpcs.ids[0], null),
    length(aws_vpc.app_vpc) > 0 ? aws_vpc.app_vpc[0].id : null
  )

  # Calculate a unique subnet CIDR
  subnet_cidr = length(data.aws_subnets.existing_subnets) > 0 ? (
    cidrsubnet(
      data.aws_vpc.selected.cidr_block,
      8,
      length(data.aws_subnets.existing_subnets[0].ids) + 1
    )
  ) : "10.0.1.0/24"
}

# Create VPC if no existing VPCs are found
resource "aws_vpc" "app_vpc" {
  count = length(data.aws_vpcs.existing_vpcs.ids) == 0 ? 1 : 0

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "app_vpc"
  }
}

# Fetch the selected VPC details
data "aws_vpc" "selected" {
  id = local.vpc_id
}

# Use availability zones data source
data "aws_availability_zones" "available" {}

# Create subnet with a unique CIDR
resource "aws_subnet" "app_subnet" {
  vpc_id            = local.vpc_id
  cidr_block        = local.subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "app_subnet"
  }
}

# Create Internet Gateway only if one doesn't exist
resource "aws_internet_gateway" "app_igw" {
  count  = length(data.aws_internet_gateway.existing_igws[0].id) == 0 ? 1 : 0
  vpc_id = local.vpc_id

  tags = {
    Name = "app_igw"
  }
}

# Data source for existing Internet Gateway if present
data "aws_internet_gateway" "existing_igw" {
  count = length(data.aws_internet_gateway.existing_igws[0].id) > 0 ? 1 : 0
  
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Create security group
resource "aws_security_group" "app_sg" {
  vpc_id = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_sg"
  }
}

# Find latest Ubuntu AMI
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Create Route Table
resource "aws_route_table" "app_rt" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = length(data.aws_internet_gateway.existing_igw) > 0 ? data.aws_internet_gateway.existing_igw[0].id : aws_internet_gateway.app_igw[0].id
  }

  tags = {
    Name = "app_route_table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "app_rta" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.app_rt.id
}

# Create EC2 instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.my_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.app_subnet.id

  associate_public_ip_address = true

  tags = {
    Name = var.app_name
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "${var.private_key}" > /home/ubuntu/.ssh/id_rsa
              chmod 600 /home/ubuntu/.ssh/id_rsa
              EOF
}

# Create key pair
resource "aws_key_pair" "my_key" {
  key_name   = "my-key-${timestamp()}"
  public_key = var.public_key
  
  lifecycle {
    ignore_changes = [key_name]
  }
}