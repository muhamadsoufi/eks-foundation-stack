resource "aws_eks_access_entry" "admin_eks_access_entry" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = "arn:aws:iam::940482451690:user/m.soufi"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_eks_access_policy_association" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::940482451690:user/m.soufi"

  access_scope {
    type       = "cluster"
  }
}

resource "null_resource" "get_kube_config" {
  depends_on = [aws_eks_access_policy_association.admin_eks_access_policy_association]

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.eks_cluster.name}
    EOT
  }
}