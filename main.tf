module "vpc" {
  source                 = "./modules/vpc"
  vpc_cidr_block         = var.vpc_cidr_block
  env                    = var.env
  tags                   = var.tags
  public_subnets         = var.public_subnets
  web_subnets            = var.web_subnets
  app_subnets            = var.app_subnets
  db_subnets             = var.db_subnets
  azs                    = var.azs
  account_id             = var.account_id
  default_vpc_id         = var.default_vpc_id
  default_route_table_id = var.default_route_table_id
  default_vpc_cidr       = var.default_vpc_cidr
}

module "rds" {
  source                = "./modules/rds"
  subnets               = module.vpc.db_subnets
  env                   = var.env
  rds_allocated_storage = var.rds_allocated_storage
  rds_engine            = var.rds_engine
  rds_engine_version    = var.rds_engine_version
  rds_instance_class    = var.rds_instance_class
  sg_cidrs              = var.app_subnets
  tags                  = var.tags
  vpc_id                = module.vpc.vpc_id
}

module "backend" {

  source = "./modules/app"
  app_port       = var.backend["app_port"]
  component      = "backend"
  env            = var.env
  instance_count = var.backend["instance_count"]
  instance_type  = var.backend["instance_type"]
  sg_cidrs       = var.app_subnets
  subnets        = module.vpc.app_subnets
  tags           = var.tags
  vpc_id         = module.vpc.vpc_id
  bastion_cidrs  = var.bastion_cidrs
  kms            = var.kms
}

module "frontend" {

  source = "./modules/app"
  app_port       = var.frontend["app_port"]
  component      = "frontend"
  env            = var.env
  instance_count = var.frontend["instance_count"]
  instance_type  = var.frontend["instance_type"]
  sg_cidrs       = var.public_subnets
  subnets        = module.vpc.web_subnets
  tags           = var.tags
  vpc_id         = module.vpc.vpc_id
  bastion_cidrs  = var.bastion_cidrs
  kms            = var.kms
}

module "public_alb" {
  source           = "./modules/alb"
  env              = var.env
  internal         = var.public_alb["internal"]
  lb_port          = var.public_alb["lb_port"]
  sg_cidrs         = ["0.0.0.0/0"]
  subnets          = module.vpc.public_subnets
  tags             = var.tags
  target_group_arn = module.frontend.target_group_arn
  type             = var.public_alb["type"]
  vpc_id           = module.vpc.vpc_id
  component        = var.public_alb["component"]
  route53_zone_id  = var.route53_zone_id
  enable_https     = var.public_alb["enable_https"]
  certificate_arn  = var.certificate_arn
  ingress          = var.public_alb["ingress"]
  dns_name         = var.env == "prod" ? "www" : null
}


module "backend-alb" {
  source           = "./modules/alb"
  env              = var.env
  internal         = var.backend_alb["internal"]
  lb_port          = var.backend_alb["lb_port"]
  sg_cidrs         = var.web_subnets
  subnets          = module.vpc.app_subnets
  tags             = var.tags
  target_group_arn = module.backend.target_group_arn
  type             = var.backend_alb["type"]
  vpc_id           = module.vpc.vpc_id
  component        = var.backend_alb["component"]
  route53_zone_id = var.route53_zone_id
  enable_https     = var.backend_alb["enable_https"]
  certificate_arn  = var.certificate_arn
  ingress          = var.backend_alb["ingress"]
}


