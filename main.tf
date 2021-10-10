terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.59.0"
    }
  }
}

provider "aws" {
  region = var.region
  # Configuration options
}


module "networking" {
  source            = "./networking"
  cidr_block        = "var.vpc_cidr"
  vpc_cidr          = local.vpc_cidr
  access_ip         = var.access_ip
  security_group    = local.security_group
  public_sn_subnet  = 2
  private_sn_subnet = 3
  max_subnet        = 5
  public_sn_count   = 2
  public_cidrs      = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs     = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group   = false
}

module "database" {
  source                = "./database"
  db_storage            = 10
  db_instance_class     = "db.t3.small"
  dbname                = var.dbname
  dbuser                = var.dbuser
  dbpassword            = var.dbpassword
  skip_db_snapshot      = true
  db_identifier         = "Test-db"
  db_subnet_group_name  = module.networking.db_subnet_group_name
  vpc_security_group_id = module.networking.db_security_group
}

module "ALB" {
  source                 = "./ALB"
  test_sg                = module.networking.test_sg
  test_subnet            = module.networking.test_subnet
  tg_port                = 80
  tg_protocol            = "HTTP"
  vpc_id                 = module.networking.vpc_id
  lb_healthy_threshold   = 2
  lb_unhealthy_threshold = 2
  lb_timeout             = 3
  lb_interval            = 30
  listener_port          = 80
  listener_protocol      = "HTTP"
}

module "compute" {
  source              = "./compute"
  test_sg             = module.networking.test_sg
  test_subnet         = module.networking.test_subnet
  instance_count      = 1
  instance_type       = "t2.small"
  vol_size            = 10
  key_name            = "test_keypair"
  public_key_path     = "C:/users/vinod Ahlawat/.ssh/newkey.pub"
  user_data_path      = "${path.root}/userdata.tpl"
  dbuser              = var.dbuser
  dbpassword          = var.dbpassword
  dbname              = var.dbname
  db_endpoint         = module.database.db_endpoint
  lb_target_group_arn = module.ALB.lb_target_group_arn
}





