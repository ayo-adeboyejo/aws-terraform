#Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  #region     = var.region
  tags       = merge(local.common_tags, { Name = local.vpc_name })
}

# ------- Subnet -----------

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidr

  tags = merge(local.common_tags, { Name = local.pub_subnet_name })
}


# ------- Internet Gateway ----------

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.common_tags, { Name = local.internet_gateway_name })
}


# ------- Route Table ----------

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(local.common_tags, { Name = local.public_route_name })
}

# ------- Route Table Association ------------
resource "aws_route_table_association" "public_route_assocciation" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

# ------- Security Group Resource and Rules -------------
resource "aws_security_group" "admin_sg" {
  name        = "admin_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  tags        = merge(local.common_tags, { Name = local.security_group_name })
}

# -------- Rule to allow SSH access -----------
resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.admin_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# -------- Rule to allow outbound traffic ----------- 
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.admin_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

