# VPC
resource "aws_vpc" "batch_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name : "batch-vpc"
  }
}

resource "aws_subnet" "batch_subnet_public" {
  for_each                = { for i in var.public_subnets : i.az => i }
  vpc_id                  = aws_vpc.batch_vpc.id
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  availability_zone       = each.value.az
}

resource "aws_subnet" "batch_subnet_private" {
  for_each          = { for i in var.private_subnets : i.az => i }
  vpc_id            = aws_vpc.batch_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "batch_ig" {
  vpc_id = aws_vpc.batch_vpc.id
}

# ルートテーブル
resource "aws_route_table" "batch_route_table_public" {
  vpc_id = aws_vpc.batch_vpc.id
}

resource "aws_route" "batch_route_public" {
  route_table_id         = aws_route_table.batch_route_table_public.id
  gateway_id             = aws_internet_gateway.batch_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "batch_route_table_private" {
  vpc_id = aws_vpc.batch_vpc.id
}

resource "aws_route_table_association" "batch_route_table_association_public" {
  for_each       = { for i in var.public_subnets : i.az => i }
  subnet_id      = aws_subnet.batch_subnet_public[each.value.az].id
  route_table_id = aws_route_table.batch_route_table_public.id
}

resource "aws_route_table_association" "batch_route_table_association_private" {
  for_each       = { for i in var.private_subnets : i.az => i }
  subnet_id      = aws_subnet.batch_subnet_private[each.value.az].id
  route_table_id = aws_route_table.batch_route_table_private.id
}

# Security Group
module "able_to_access_rds_sg" {
  source = "./modules/security_group"
  name   = "able-to-access-rds-sg"
  vpc_id = aws_vpc.batch_vpc.id
  ports  = []
}

module "vpc_endpoint_sg" {
  source      = "./modules/security_group"
  name        = "vpc-endpoint-sg"
  vpc_id      = aws_vpc.batch_vpc.id
  ports       = [443]
  cidr_blocks = [aws_vpc.batch_vpc.cidr_block]
}

module "batch_db_sg" {
  source                   = "./modules/security_group"
  name                     = "batch-db--sg"
  vpc_id                   = aws_vpc.batch_vpc.id
  ports                    = [3306]
  source_security_group_id = module.able_to_access_rds_sg.security_group_id
}

# VPC Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.batch_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  subnet_ids          = [for i in aws_subnet.batch_subnet_private : i.id]
  private_dns_enabled = true
  security_group_ids = [
    module.vpc_endpoint_sg.security_group_id
  ]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.batch_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  subnet_ids          = [for i in aws_subnet.batch_subnet_private : i.id]
  private_dns_enabled = true
  security_group_ids = [
    module.vpc_endpoint_sg.security_group_id
  ]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.batch_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  subnet_ids          = [for i in aws_subnet.batch_subnet_private : i.id]
  private_dns_enabled = true
  security_group_ids = [
    module.vpc_endpoint_sg.security_group_id
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.batch_vpc.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  policy            = data.aws_iam_policy_document.vpc_endpoint_for_s3.json
  route_table_ids = [
    aws_route_table.batch_route_table_private.id
  ]
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.batch_vpc.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  subnet_ids          = [for i in aws_subnet.batch_subnet_private : i.id]
  private_dns_enabled = true
  security_group_ids = [
    module.vpc_endpoint_sg.security_group_id
  ]
}
