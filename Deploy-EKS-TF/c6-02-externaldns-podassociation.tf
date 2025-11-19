resource "aws_eks_pod_identity_association" "externaldns_assoc" {
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_id
  namespace    = "external-dns"
  service_account = "external-dns"
  role_arn     = aws_iam_role.externaldns_iam_role.arn
  depends_on = [ helm_release.external_dns ]
}


