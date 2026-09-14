terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider instellen (geen credentials nodig voor 'terraform validate')
provider "aws" {
  region = "eu-central-1" # Frankfurt (vaak gebruikt voor latency/GDPR)
}

# 1. Netwerk Fundering
module "vpc_hub" {
  source = "./modules/vpc-hub"
}

module "vpc_web" {
  source = "./modules/vpc-web"
}

module "vpc_data" {
  source = "./modules/vpc-data"
}

module "transit_gateway" {
  source = "./modules/transit-gateway"
  # Hier geef je straks de VPC ID's door als variabelen
  # hub_vpc_id  = module.vpc_hub.vpc_id
  # web_vpc_id  = module.vpc_web.vpc_id
  # data_vpc_id = module.vpc_data.vpc_id
}

# 2. Opslag & Container Registry
module "ecr" {
  source = "./modules/ecr"
}

module "database" {
  source = "./modules/database"
  # data_vpc_id = module.vpc_data.vpc_id
}

# 3. Compute & Front-end
module "compute" {
  source = "./modules/compute"
  # web_vpc_id = module.vpc_web.vpc_id
}

# 4. Monitoring
module "monitoring" {
  source = "./modules/monitoring"
}