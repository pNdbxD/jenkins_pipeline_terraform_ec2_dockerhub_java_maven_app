provider "aws" {
    region = var.region
}

locals {
  project_prefix = "${var.project_name_prefix}-${var.env_prefix}"
}

resource "aws_vpc" "tf1-vpc-1" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${local.project_prefix}-vpc"
  }
}

resource "aws_subnet" "tf1-subnet-1" {
  vpc_id = aws_vpc.tf1-vpc-1.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${local.project_prefix}-subnet-1"
  }
}

resource "aws_route_table" "tf1-route-table-1" {
  vpc_id = aws_vpc.tf1-vpc-1.id
  route {
    # default one is created automatically
    cidr_block = "0.0.0.0/0"  # for internet access
    gateway_id = aws_internet_gateway.tf1-igw-1.id
  }
  tags = {
    Name: "${local.project_prefix}-route-table-1"
  }
}

resource "aws_internet_gateway" "tf1-igw-1" {
  vpc_id = aws_vpc.tf1-vpc-1.id
  tags = {
    Name: "${local.project_prefix}-igw-1"
  }
}

resource "aws_route_table_association" "tf1-route-table-assoc-1" {
  subnet_id = aws_subnet.tf1-subnet-1.id
  route_table_id = aws_route_table.tf1-route-table-1.id
}

# to open ports for ssh and 8080
resource "aws_security_group" "tf1-sg-1" {
  name        = "${local.project_prefix}-sg-1"
  description = "Allow SSH and 8080 access"
  vpc_id      = aws_vpc.tf1-vpc-1.id

  # for incoming traffic
  ingress {
    from_port = 22
    to_port   = 22 # can define range here
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # open to all for testing, not recommended for production
  }
  ingress {
    from_port = 8080
    to_port   = 8080 # can define range here
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # open to all for testing, not recommended for production
  }

  # for outgoing traffic, like installing smth on server
  egress {
    from_port = 0
    to_port   = 0
    protocol = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${local.project_prefix}-sg-1"
  }
}


# EC2
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}



resource "aws_instance" "tf1-ec2-1" {
  # ami           = "ami-0272e4a5becbb6268" # Amazon Linux 2023 kernel-6.18 AMI
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.tf1-subnet-1.id
  vpc_security_group_ids = [aws_security_group.tf1-sg-1.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true

  key_name = var.key_name

  user_data = file("entry-script.sh")

  user_data_replace_on_change = true


  tags = {
    Name = "${local.project_prefix}-ec2-1"
  }

}





output "aws_ami_id" {
  value = data.aws_ami.amazon_linux_2023.id
}


output "ec2_public_ip" {
  value = aws_instance.tf1-ec2-1.public_ip
}

