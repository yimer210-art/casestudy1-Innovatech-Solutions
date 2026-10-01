terraform {
  backend "s3" {
    bucket = "innovatech-tfstate-805778285824"
    key    = "terraform.tfstate"
    region = "eu-central-1"
    profile = "terraform"
  }
}

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

module "vpc_data" {
  source                 = "./modules/vpc-data"
  db_password             = var.db_password
}

module "vpc_hub" {
  source             = "./modules/vpc-hub"
  admin_cidr         = var.admin_cidr
  bastion_public_key = var.bastion_public_key
}

module "transit_gateway" {
  source = "./modules/transit-gateway"

  web_vpc_id         = module.vpc_web.vpc_id
  web_subnet_ids     = module.vpc_web.private_subnet_ids
  web_route_table_id = module.vpc_web.private_route_table_id

  data_vpc_id         = module.vpc_data.vpc_id
  data_subnet_ids     = module.vpc_data.subnet_ids
  data_route_table_id = module.vpc_data.main_route_table_id

  hub_vpc_id         = module.vpc_hub.vpc_id
  hub_subnet_ids     = [module.vpc_hub.subnet_id]
  hub_route_table_id = module.vpc_hub.route_table_id
}

module "monitoring" {
  source = "./modules/monitoring"

  # Haal deze waarden uit de outputs van je compute module
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.ecs_service_name
  alb_arn_suffix   = module.compute.alb_arn_suffix
  
  # Haal deze waarde uit de output van je vpc-data / database module
  rds_cluster_identifier = module.vpc_data.rds_identifier
}