# -- root/main.tf --

#Define VPC
module "networking" {
  source          = "./networking"
  vpc_cidr        = local.vpc_cidr #References locals.tf variable
  max_subnets     = 10
  public_sn_count = 2
  public_cidrs    = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)] #Generates list of public_cidrs to use
}