# Terraform Settings Block
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = ">= 4.65"
      version = ">= 5.31"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
     }
  }
  backend "s3" {
    bucket = "terraform-on-aws-eks-xxxxxxxxxxx123123123"
    key    = "dev/terraform-on-aws-eks-xxxxxxxxxxx123123123/terraform.tfstate"
    region = "us-east-1"
 
    # For State Locking
    dynamodb_table = "terraform-on-aws-eks-xxxxxxxxxxx123123123"
  }  
}

# Terraform Provider Block
provider "aws" {
    region = "us-east-1"
}


# Datasource: EKS Cluster Auth 
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

# HELM Provider
provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}