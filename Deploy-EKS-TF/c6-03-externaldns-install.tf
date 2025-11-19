# Resource: Helm Release 
resource "helm_release" "external_dns" {
  depends_on = [aws_iam_role.externaldns_iam_role, resource.aws_eks_cluster.eks_cluster]  

  name       = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  create_namespace = true
  namespace = "external-dns"     

  set = [
    {
    name = "image.repository"
    #value = "k8s.gcr.io/external-dns/external-dns" 
    value = "registry.k8s.io/external-dns/external-dns"
    },
    {
    name  = "serviceAccount.create"
    value = "true"
    },
    {
    name  = "serviceAccount.name"
    value = "external-dns"
    },
    {
    name  = "provider" # Default is aws (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
    value = "aws"
    },
    {
    name  = "policy" # Default is "upsert-only" which means DNS records will not get deleted even equivalent Ingress resources are deleted (
    value = "sync"   # "sync" will ensure that when ingress resource is deleted, equivalent DNS record in Route53 will get deleted
    }
  ]
}


resource "null_resource" "externaldns_restart" {
  depends_on = [aws_eks_pod_identity_association.externaldns_assoc, null_resource.get_kube_config]

  provisioner "local-exec" {
    command = <<EOT
      kubectl -n external-dns rollout restart deployment external-dns
    EOT
  }
}
