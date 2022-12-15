# -- root/main.tf --

#Define VPC
module "networking" {
  source          = "./networking"
  vpc_cidr        = local.vpc_cidr #References locals.tf variable
  max_subnets     = 10
  public_sn_count = 2
  web_sn_count = 2
  rds_sn_count = 2
  public_cidrs    = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)] #Generates list of public_cidrs to use
  web_cidrs = [for i in range(1, 255, 4) : cidrsubnet(local.vpc_cidr, 8, i)] #Create list of private cidrs to use for web tier
  rds_cidrs = [for i in range(3, 255, 4) : cidrsubnet(local.vpc_cidr, 8, i)] #Create list of private cidrs to use for rds tier
}

#
module "security"{
    source = "./security"
    access_ip = var.access_ip
    vpc_id = module.networking.my_vpc_id
}