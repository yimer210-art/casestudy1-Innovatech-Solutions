terraform {
  backend "s3" {
    bucket  = "innovatech-tfstate-805778285824"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    profile = "terraform"
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "terraform"
}

# ==========================================
# Case Study 1 Baseline Modules
# ==========================================

module "vpc_web" {
  source = "./modules/vpc-web"
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.vpc_web.vpc_id
  public_subnet_ids  = module.vpc_web.public_subnet_ids
  private_subnet_ids = module.vpc_web.private_subnet_ids
}

module "vpc_data" {
  source      = "./modules/vpc-data"
  db_password = var.db_password
}

module "vpc_hub" {
  source             = "./modules/vpc-hub"
  admin_cidr         = var.admin_cidr
  bastion_public_key = var.bastion_public_key
}

module "monitoring" {
  source = "./modules/monitoring"

  ecs_cluster_name       = module.compute.ecs_cluster_name
  ecs_service_name       = module.compute.ecs_service_name
  alb_arn_suffix         = module.compute.alb_arn_suffix
  rds_cluster_identifier = module.vpc_data.rds_identifier
  security_vpc_id        = module.vpc_security.vpc_id
  branch_vpc_id          = module.vpc_branch.vpc_id
}

# ==========================================
# Case Study 2 Extended Modules
# ==========================================

# Spoke 3: Security & Observability (Loki, Prometheus, Grafana, Shuffle SOAR)
module "vpc_security" {
  source     = "./modules/vpc-security"
  admin_cidr = var.admin_cidr
  hub_cidr   = "10.2.0.0/16"
}

# Spoke 4: Branch Office (Workstation-01 & Branch-Server-01)
module "vpc_branch" {
  source        = "./modules/vpc-branch"
  admin_cidr    = var.admin_cidr
  hub_cidr      = "10.2.0.0/16"
  security_cidr = "10.3.0.0/16"
}

# Transit Gateway (Hub-and-Spoke interconnectie tussen alle 5 VPC's)
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

  security_vpc_id         = module.vpc_security.vpc_id
  security_subnet_ids     = [module.vpc_security.subnet_id]
  security_route_table_id = module.vpc_security.route_table_id

  branch_vpc_id         = module.vpc_branch.vpc_id
  branch_subnet_ids     = [module.vpc_branch.subnet_id]
  branch_route_table_id = module.vpc_branch.route_table_id
}

# Route 53 Private Hosted Zone (innovatech.internal - REQ-04)
module "dns" {
  source = "./modules/dns"

  hub_vpc_id      = module.vpc_hub.vpc_id
  web_vpc_id      = module.vpc_web.vpc_id
  data_vpc_id     = module.vpc_data.vpc_id
  security_vpc_id = module.vpc_security.vpc_id
  branch_vpc_id   = module.vpc_branch.vpc_id

  security_ip      = module.vpc_security.private_ip
  workstation_ip   = module.vpc_branch.workstation_private_ip
  branch_server_ip = module.vpc_branch.branch_server_private_ip
  attacker_ip      = module.vpc_branch.attacker_private_ip
}
