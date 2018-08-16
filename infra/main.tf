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

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.19.0"

  parameter_group_name = "default.mysql5.7"

  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "5.7.22"
  instance_class    = "db.m4.large"            #db.t2.micro does not support encryption at rest
  allocated_storage = 20
  multi_az          = true
  apply_immediately = true
  storage_encrypted = true
  kms_key_id        = "${aws_kms_key.rds.arn}"

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
  skip_final_snapshot       = true

  vpc_security_group_ids = ["${module.db-sg.this_security_group_id}"]
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "2.7.0"
  name    = "demo-asg"

  # Auto scaling group


  # Bit of a hack to get asg to wait on rds
  # Since module dependencies aren't implmented
  # https://github.com/hashicorp/terraform/issues/117

  asg_name            = "demo-asg-${module.rds.this_db_instance_name}"
  min_size            = "1"
  max_size            = "10"
  desired_capacity    = 5
  health_check_type   = "ELB"
  key_name            = ""
  vpc_zone_identifier = ["${module.vpc.private_subnets}"]
  user_data           = "${data.template_file.user_data.rendered}"
  target_group_arns   = ["${module.alb.target_group_arns}"]

  # Launch configuration

  lc_name         = "demo-lc"
  key_name        = "${aws_key_pair.terraform.key_name}"
  image_id        = "ami-18726478"                               # RHEL 7.5
  instance_type   = "t2.micro"
  security_groups = ["${module.http-sg.this_security_group_id}"]
  root_block_device = [
    {
      volume_size = "10"
      volume_type = "gp2"
    },
  ]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "3.4.0"

  load_balancer_name       = "demo-alb"
  vpc_id                   = "${module.vpc.vpc_id}"
  subnets                  = "${module.vpc.public_subnets}"
  security_groups          = ["${module.alb-sg.this_security_group_id}"]
  http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count = "1"
  target_groups            = "${list(map("name", "alb-demo-web", "backend_protocol", "HTTP", "backend_port", "80"))}"
  target_groups_count      = "1"
  logging_enabled          = false
}

module "alb-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"

  name   = "alb-sg"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = ["http-80-tcp"]

  egress_cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks}"]
  egress_rules       = ["http-80-tcp"]
}

module "http-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"

  name   = "http-sg"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["${module.vpc.public_subnets_cidr_blocks}"]

  ingress_rules = ["ssh-tcp", "http-80-tcp"]

  egress_cidr_blocks = ["${module.vpc.database_subnets_cidr_blocks}"]
  egress_rules       = ["mysql-tcp"]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "db-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"

  name   = "db-sg"
  vpc_id = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["${module.vpc.private_subnets_cidr_blocks}"]
  ingress_rules       = ["mysql-tcp"]
}

data "template_file" "user_data" {
  template = "${file("user_data.sh")}"

  vars {
    db_user     = "${module.rds.this_db_instance_username}"
    db_pass     = "${module.rds.this_db_instance_password}"
    db_table    = "${module.rds.this_db_instance_name}"
    db_endpoint = "${module.rds.this_db_instance_endpoint}"

    # db_port     = "${module.rds.this_db_instance_port}"
  }
}

output "userdata" {
  value = "${data.template_file.user_data.rendered}"
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = "${file("terraform.pub")}"
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for encrypting rds storage"
  deletion_window_in_days = 7
}

# TODO: Turn these into bastion
/*
 *resource "aws_instance" "test" {
 *  count                       = 2
 *  ami                         = "ami-18726478"                               # RHEL 7.5
 *  instance_type               = "t2.micro"
 *  key_name                    = "${aws_key_pair.terraform.key_name}"
 *  associate_public_ip_address = true
 *  user_data                   = "${data.template_file.user_data.rendered}"
 *  subnet_id                   = "${module.vpc.public_subnets[0]}"
 *  vpc_security_group_ids      = ["${module.test-sg.this_security_group_id}"]
 *}
 *
 *module "test-sg" {
 *  source  = "terraform-aws-modules/security-group/aws"
 *  version = "2.1.0"
 *
 *  name   = "test-sg"
 *  vpc_id = "${module.vpc.vpc_id}"
 *
 *  ingress_cidr_blocks = ["0.0.0.0/0"]
 *
 *  ingress_rules = ["ssh-tcp", "http-80-tcp"]
 *}
 */

