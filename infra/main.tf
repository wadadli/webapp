provider "aws" {
  profile = "techcafe"
  region  = "us-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.37.0"

  name = "demo-vpc"
  cidr = "10.20.0.0/16"

  azs              = ["us-west-1a", "us-west-1c"]
  database_subnets = ["10.20.10.0/24", "10.20.11.0/24"]
  private_subnets  = ["10.20.20.0/24", "10.20.21.0/24"]
  public_subnets   = ["10.20.30.0/24", "10.20.31.0/24"]

  create_vpc                       = true
  default_vpc_enable_dns_hostnames = false
  default_vpc_enable_dns_support   = true
  create_database_subnet_group     = true
  enable_nat_gateway               = true
  single_nat_gateway               = false
  one_nat_gateway_per_az           = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  parameter_group_name = "default.mysql5.7"

  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "5.7.22"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  multi_az          = true

  name     = "demodb"
  username = "wadadli"
  password = "${var.rds_key}"
  port     = "3306"

  iam_database_authentication_enabled = false

  maintenance_window = "Sun:00:00-Sun:03:00"
  backup_window      = "03:00-06:00"

  subnet_ids = ["${module.vpc.database_subnets}"]

  family = "mysql5.7"

  major_engine_version = "5.7"

  final_snapshot_identifier = "demodb"
}
