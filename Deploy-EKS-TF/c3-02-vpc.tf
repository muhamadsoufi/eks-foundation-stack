# Create VPC Terraform Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
    
  # VPC Basic Details
  name = var.vpc_name
  cidr = var.vpc_cidr_block   
  azs                 = var.vpc_availability_zones
  private_subnets     = var.vpc_private_subnets
  public_subnets      = var.vpc_public_subnets

  # Database Subnets
  create_database_subnet_group = var.vpc_create_database_subnet_group
  create_database_subnet_route_table= var.vpc_create_database_subnet_route_table
  database_subnets    = var.vpc_database_subnets

  #create_database_nat_gateway_route = true
  #create_database_internet_gateway_route = true

  # NAT Gateways - Outbound Communication
  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway

  # VPC DNS Parameters
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  enable_dns_support = var.vpc_enable_dns_support

  public_subnet_tags = {
    Type = "Public Subnets"
    "kubernetes.io/role/elb" = 1    
    "kubernetes.io/cluster/sales-dept-dev-eksdemo" = "shared"        
  }
  private_subnet_tags = {
    Type = "private-subnets"
    "kubernetes.io/role/internal-elb" = 1    
    "kubernetes.io/cluster/sales-dept-dev-eksdemo" = "shared"    
  }

  database_subnet_tags = {
    Type = "database-subnets"
  }

  tags = local.common_tags

  vpc_tags = {
    Name = "vpc-dev"
  }
  # Instances launched into the Public subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
}



