data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks-xxxxxxxxxxx123123123"
    key    = "dev/terraform-on-aws-eks-xxxxxxxxxxx123123123/terraform.tfstate"
    region = "us-east-1"
  }
}