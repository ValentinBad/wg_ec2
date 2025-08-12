
provider "aws" {
  region = var.aws_region
}

# Use the public SSM parameter that always points to the latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "wg-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = { Name = "wg-subnet-public" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "wg-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "wg-rt" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "sg" {
  name        = "wg-sg"
  description = "Allow SSH and WireGuard"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "WireGuard UDP"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wg-sg" }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "wg" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # user_data will read the local file wireguard-server.sh (save it next to main.tf)
  user_data = <<EOF
#!/bin/bash
curl -o /tmp/wireguard-server.sh https://raw.githubusercontent.com/ValentinBad/wg_ec2/main/wireguard-server.sh
chmod +x /tmp/wireguard-server.sh
/tmp/wireguard-server.sh
EOF


  tags = {
    Name = "wireguard-server"
  }
}


# --- notes ---
# 1) Place wireguard-server.sh in the same folder as this Terraform config.
# 2) Run: terraform init && terraform apply -var 'key_name=your-key' -var 'public_key_path=/home/me/.ssh/id_rsa.pub'
# 3) The AMI is resolved dynamically using the SSM public parameter for Amazon Linux 2023.
#    This avoids hardcoding an AMI id that changes between regions and over time.
