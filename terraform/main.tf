provider "aws" {
  region  = "eu-central-1"
  profile = "terraform"
}

module "vpc_web" {
  source = "./modules/vpc-web"
}

module "compute" {
  source              = "./modules/compute"
  vpc_id              = module.vpc_web.vpc_id
  public_subnet_ids   = module.vpc_web.public_subnet_ids
  private_subnet_ids  = module.vpc_web.private_subnet_ids
}