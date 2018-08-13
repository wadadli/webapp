provider "aws" {
    profile = "techcafe"
    region = "us-west-1"
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "1.37.0"
    name = "dev"

    cidr = "10.20.0.0/16"
    azs = ["us-west-1a", "us-west-1c"]
    database_subnets = ["10.20.10.0/24"]
    private_subnets = ["10.20.20.0/24"]
    public_subnets = ["10.20.30.0/24"]
    enable_nat_gateway = true
}
