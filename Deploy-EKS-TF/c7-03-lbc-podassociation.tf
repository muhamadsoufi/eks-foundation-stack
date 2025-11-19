resource "aws_eks_pod_identity_association" "lbc_assoc" {
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_id
  namespace    = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn     = aws_iam_role.lbc_iam_role.arn
  depends_on = [ helm_release.loadbalancer_controller ]
}