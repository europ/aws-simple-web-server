#####################################################################
# other

# zone in region
data "aws_availability_zone" "avail_zone" {
  name = "${var.aws_region}${var.aws_zone}"
}

# ssh key pair
resource "aws_key_pair" "key-pair-1" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = file(var.ssh_public_key_path)
}

#####################################################################
# network(s), address(es), firewall(s)

# network
resource "aws_vpc" "net_1" { # VPC - Virtual Private Cloud
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-network-1"
  }
}

# network gateway
resource "aws_internet_gateway" "net_1_gw_1" {
  vpc_id = aws_vpc.net_1.id

  tags = {
    Name = "${var.prefix}-network-1-gateway-1"
  }
}

# network gateway route-table
resource "aws_route_table" "net_1_gw_1_rt" {
  vpc_id = aws_vpc.net_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net_1_gw_1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.net_1_gw_1.id
  }

  tags = {
    Name = "${var.prefix}-network-1-gateway-1-routetable"
  }
}

# subnet in network
resource "aws_subnet" "net_1_subnet_1" {
  vpc_id                  = aws_vpc.net_1.id

  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone_id    = data.aws_availability_zone.avail_zone.zone_id

  depends_on              = [aws_internet_gateway.net_1_gw_1]

  tags = {
    Name = "${var.prefix}-network-1-subnet-1"
  }
}

# subnet in network <=> network gateway route-table
resource "aws_route_table_association" "net_1_subnet_1_rt" {
  subnet_id      = aws_subnet.net_1_subnet_1.id
  route_table_id = aws_route_table.net_1_gw_1_rt.id
}

# firewall
resource "aws_security_group" "sec_grp_1" {
  vpc_id      = aws_vpc.net_1.id

  name        = "${var.prefix}-security-group-1"
  description = "Allow: IN[ICMP,SSH,HTTP,HTTPS], OUT[*]"

  # IN-coming

    # allow ICMP from specific IP
    ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "icmp"
      cidr_blocks = var.accessible_from
    }

    # allow SSH from specific IP
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.accessible_from
    }

    # allow HTTP from specific IP
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.accessible_from
    }

    # allow HTTPS from specific IP
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.accessible_from
    }

  # OUT-going

    # allow all
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

#####################################################################
# machine(s)

# boot image
data "aws_ami" "debian_image" { # AMI - Amazon Machine Image
  most_recent = true # latest stable

  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Debian Cloud Team
  owners = ["136693071363"] # https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
}

# virtual machine's network interface
resource "aws_network_interface" "netif_1" {
  subnet_id       = aws_subnet.net_1_subnet_1.id
  security_groups = [aws_security_group.sec_grp_1.id]

  tags = {
    Name = "${var.prefix}-network-1-subnet-1-interface-1"
  }
}

# public IP
resource "aws_eip" "pub_addr_1" {
  vpc = true

  network_interface = aws_network_interface.netif_1.id # virtual machine's network interface
  depends_on        = [aws_internet_gateway.net_1_gw_1] # network gateway
}

# virtual machine
resource "aws_instance" "virtual_machine" {
  ami               = data.aws_ami.debian_image.id
  instance_type     = "t3.micro" # https://aws.amazon.com/ec2/instance-types/
  availability_zone = data.aws_availability_zone.avail_zone.name
  tags = {
    Name = "${var.prefix}-virtual-machine"
  }

  key_name        = aws_key_pair.key-pair-1.id

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.netif_1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y dist-upgrade
    sudo apt-get -y install nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
  EOF
}
