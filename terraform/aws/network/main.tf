resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr

  enable_dns_hostnames  = var.dns_hostnames
  enable_dns_support    = var.dns_support

  tags = {
    Name = var.project_name
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "main" {
  count = length(var.vpc_additional_cidrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.vpc_additional_cidrs[count.index]
}



resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.main.id

  cidr_block        = var.public_subnets[count.index].cidr
  availability_zone = var.public_subnets[count.index].availability_zone

  tags = {
    Name = var.public_subnets[count.index].name
  }

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.main
  ]
}

resource "aws_route_table" "public_internet_access" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-access"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public_internet_access.id
  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_internet_access.id
}



resource "aws_eip" "eip" {
  count = length(var.public_subnets)
  domain = "vpc"
  
  tags = {
    Name = format("%s-%s", var.project_name, var.public_subnets[count.index].availability_zone)
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.public_subnets)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id = aws_subnet.public[count.index].id
  tags = {
    Name = format("%s-%s", var.project_name, var.public_subnets[count.index].availability_zone)
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].availability_zone

  tags = {
    Name = var.private_subnets[count.index].name
  }

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.main
  ]
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-%s", var.project_name, var.private_subnets[count.index].name)
  }
}

resource "aws_route" "private" {
  count = length(var.private_subnets)
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.private[count.index].id
  
  gateway_id = aws_nat_gateway.main[
    index(
      var.public_subnets[*].availability_zone,
      var.private_subnets[count.index].availability_zone
    )
  ].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}



resource "aws_subnet" "database" {
  count = length(var.database_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block        = var.database_subnets[count.index].cidr
  availability_zone = var.database_subnets[count.index].availability_zone
  tags = {
    Name = var.database_subnets[count.index].name
  }
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.main
  ]
}

resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id
  egress {
    rule_no    = 200
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = format("%s-databases", var.project_name)
  }
}

resource "aws_network_acl_rule" "deny" {
  network_acl_id = aws_network_acl.database.id
  rule_number    = "300"
  rule_action    = "deny"
  protocol = "-1"
  cidr_block = "0.0.0.0/0"
  from_port  = 0
  to_port    = 0
}

resource "aws_network_acl_association" "database" {
  count = length(var.database_subnets)
  network_acl_id = aws_network_acl.database.id
  subnet_id      = aws_subnet.database[count.index].id
}


resource "aws_network_acl_rule" "allow_3306" {
  count = length(var.private_subnets)
  network_acl_id = aws_network_acl.database.id
  rule_number    = 10 + count.index
  egress = false
  rule_action = "allow"
  protocol = "tcp"
  cidr_block = aws_subnet.private[count.index].cidr_block
  from_port  = 3306
  to_port    = 3306
}


resource "aws_network_acl_rule" "allow_6379" {
  count = length(var.private_subnets)
  network_acl_id = aws_network_acl.database.id
  rule_number    = 20 + count.index
  egress = false
  rule_action = "allow"
  protocol = "tcp"
  cidr_block = aws_subnet.private[count.index].cidr_block
  from_port  = 6379
  to_port    = 6379
}



resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.project_name
  }
}



