provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

###############################################################################
# Providers
###############################################################################

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint                                 # var.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data) # var.cluster_ca_cert
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"                                                       # /v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_name] # var.cluster_name
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint                                 # var.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data) # var.cluster_ca_cert
    exec {
      api_version = "client.authentication.k8s.io/v1beta1" # /v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint                                 # var.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data) # var.cluster_ca_cert
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"                                                       # /v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks.outputs.cluster_name] # var.cluster_name
    command     = "aws"
  }
}

###############################################################################
# Read state from eks cluster to extract outputs
###############################################################################

data "terraform_remote_state" "eks" {
  backend = "local" # Pending remote set up to enable collaboration, state locking etc.
  config = {
    path = "${path.module}/../01-eks-cluster/terraform.tfstate"
  }
}

################################################################################
# Argocd
################################################################################

locals {
  argocd_config = yamldecode(file("${path.module}/../../argo-apps/argocd/argocd-helm.yaml"))
}

resource "helm_release" "argocd" {
  name       = local.argocd_config.spec.source.helm.valuesObject.fullnameOverride
  chart      = local.argocd_config.spec.source.chart
  repository = local.argocd_config.spec.source.repoURL
  version    = local.argocd_config.spec.source.targetRevision
  timeout    = "1500"
  namespace  = local.argocd_config.metadata.namespace

  create_namespace = true
  values           = [yamlencode(local.argocd_config.spec.source.helm.valuesObject)]

  set {
    name  = "repoServer.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.terraform_remote_state.eks.outputs.argo_cd_repo_iam_role_arn
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
          kubectl get crd -o name |
          grep -E 'argoproj.io|monitoring.coreos.com|fluent.io|elastic.co' |
          xargs -I {} kubectl patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge &&
          kubectl -n argocd get app -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' |
          xargs -I {} kubectl delete all,pvc,secrets,configmaps,ingresses,networkpolicies,serviceaccounts,jobs,cronjobs,applicationsets --all -n {}
        EOT
  }
}

## ArgoCD apply ApplicationSet
## Uses directory generator to dynamically create argo-apps in subdirectories
## Kustomize uses helmChart for 3rd party charts with local repo overrides (values.yaml) and load additional k8s manifests

resource "kubectl_manifest" "example_applicationset" {
  yaml_body = file("${path.module}/../../argo-apps/argocd/applicationset.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

# print argocd password after tf apply
resource "null_resource" "get_argocd_admin_password" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
    EOT
  }

  depends_on = [
    helm_release.argocd
  ]
}

