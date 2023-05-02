provider "aws" {
  region     = "eu-west-3"
  access_key = ""
  secret_key = ""
}

#create vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#create internet gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

#create route table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "example"
  }
}

#create a subnet

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

#associate subnet to the route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table.id
}

#create a securty policy for the vpc

resource "aws_security_group" "security" {
  name        = "allow_web"
  description = "vpc policy"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #you can changed with the address(s) that you want to allow access
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #you can changed with the address(s) that you want to allow access
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #you can changed with the address(s) that you want to allow access
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#create a network interface
resource "aws_network_interface" "net" {
  subnet_id       = aws_subnet.subnet_1.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.security.id]
}

#create an eip

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.net.id
  associate_with_private_ip = "10.0.0.50"
  depends_on                = [aws_internet_gateway.gateway]
}


resource "aws_instance" "ubuntu" {
  ami           = "ami-05e8e219ac7e82eba"
  instance_type = "t2.micro"
  key_name      = "project 1 terraform"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.net.id
  }
  subnet_id = aws_subnet.subnet_1.id
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                EOF
}
