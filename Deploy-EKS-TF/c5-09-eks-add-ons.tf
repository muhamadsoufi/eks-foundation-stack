

resource "aws_eks_addon" "all_add_ones" {

  for_each = toset(var.cluster_add_ons)
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = each.key
}

/*
resource "aws_iam_role" "vpc_cni_eks_pod_identity_role" {
  name = "vpc-cni-eks-pod-identity-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "pods.eks.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
})
}


resource "aws_iam_role_policy_attachment" "eks_pod_identity_policy_attachment" {
  role       = aws_iam_role.vpc_cni_eks_pod_identity_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Policy for VPC CNI
}



resource "aws_eks_pod_identity_association" "vpc_cni_association" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni_eks_pod_identity_role.arn
}



resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  depends_on = [ aws_eks_pod_identity_association.vpc_cni_association ]
}

*/