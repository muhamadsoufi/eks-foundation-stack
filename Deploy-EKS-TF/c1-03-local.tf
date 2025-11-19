# Define Local Values in Terraform
locals {
  owners = var.business_divsion
  environment = var.environment
  name = "${var.business_divsion}-${var.environment}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners = local.owners
    environment = local.environment
  }
  eks_cluster_name = "eks-al2023-${local.name}"
  eks_cluster_tags = {
    owners = local.owners
    environment = local.environment
    Name = local.eks_cluster_name
  }  
} 