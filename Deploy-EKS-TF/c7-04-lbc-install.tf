# Install AWS Load Balancer Controller using HELM

# Resource: Helm Release 
resource "helm_release" "loadbalancer_controller" {
  depends_on = [aws_iam_role.lbc_iam_role]            
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system"     

  # Value changes based on your Region (Below is for us-east-1)
  set = [{
    name = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller" 
    # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
    },
    {
    name  = "serviceAccount.create"
    value = "true"
    },
    {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
    },
    {
    name  = "vpcId"
    value = "${data.terraform_remote_state.eks.outputs.vpc_id}"
    },
    {
    name  = "region"
    value = "${var.aws_region}"
    },
    {
    name  = "clusterName"
    value = "${data.terraform_remote_state.eks.outputs.cluster_id}"
  }]

}

# Restart LBC Deployment to pick up the new Pod Identity Association
resource "null_resource" "lbc_restart" {
  depends_on = [aws_eks_pod_identity_association.lbc_assoc, null_resource.get_kube_config]

  provisioner "local-exec" {
    command = <<EOT
      kubectl -n kube-system rollout restart deployment aws-load-balancer-controller
    EOT
  }
}