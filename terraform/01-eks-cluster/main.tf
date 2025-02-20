data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name     = "demo-${var.TF_ENVIRONMENT}" # cluster name
  domain   = var.TF_DOMAIN
  repo_url = var.TF_REPO_URL

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.name
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)

  rds_user   = "django"   # django rds
  rds_dbname = "postgres" # django rds
  rds_port   = 5432       # postgres default # django rds

  sonar_rds_user   = "sonarqube"
  sonar_rds_dbname = "postgres"
  sonar_rds_port   = 5432

  # SSM Parameter values
  parameters = {
    # aws
    "aws_account_id" = {
      name  = "aws/account_id"
      value = local.aws_account_id
    }
    "aws_region" = {
      name  = "aws/region"
      value = local.aws_region
    }

    # cluster
    "cluster_name" = {
      name  = "cluster/name"
      value = local.name
    }
    "cluster_domain" = {
      name  = "cluster/domain"
      value = local.domain
    }

    # argocd
    "argo_cd_admin_password" = {
      name  = "argo/cd/admin/password"
      value = random_password.argocd_password.result
    }
    "argo_cd_ecr_domain" = {
      name  = "argo/cd/ecr/domain"
      value = split("/", module.ecr.repository_url)[0] # retains only the ecr domain <ecr domain>/<repo name>
    }
    "argo_cd_ecr_repo_name" = {
      name  = "argo/cd/ecr/repo_name"
      value = module.ecr.repository_name
    }
    "argo_cd_iam_repo_role_arn" = {
      name  = "argo/cd/iam/repo_role_arn"
      value = aws_iam_role.argocd_repo.arn
    }
    "argo_cd_iam_updater_role_arn" = {
      name  = "argo/cd/iam/updater_role_arn"
      value = aws_iam_role.argocd_image_updater.arn
    }

    # argocd image updater
    "argo_cd_image_updater_github_user" = {
      name  = "argo/cd/image_updater/github/user"
      value = var.ARGOCD_GITHUB_USER
    }
    "argo_cd_image_updater_github_token" = {
      name  = "argo/cd/image_updater/github/token"
      value = var.ARGOCD_GITHUB_TOKEN
    }

    # django
    "app_iam_role_arn" = {
      name  = "app/iam/role_arn"
      value = aws_iam_role.django.arn
    }
    "app_django_debug" = {
      name  = "app/django/debug"
      value = "FALSE"
    }
    "app_django_secret_key" = {
      name  = "app/django/secret_key"
      value = random_password.django_secretkey.result
    }
    "app_db_name" = {
      name  = "app/db/name"
      value = local.rds_dbname
    }
    "app_db_host" = {
      name  = "app/db/host"
      value = split(":", module.db.db_instance_endpoint)[0] # regular output includes `endpoint:port`, this filters out the port
    }
    "app_db_port" = {
      name  = "app/db/port"
      value = local.rds_port
    }
    "app_db_username" = {
      name  = "app/db/username"
      value = local.rds_user
    }
    "app_db_password" = { # pending # make type secret after test
      name  = "app/db/password"
      value = random_password.database_password.result # pending. figure out how not to include in tf state
    }
    "app_repo_url" = {
      name  = "app/repo_url"
      value = local.repo_url # right now the name of the cluster is being used for the app name # pending
    }

    # ecr
    # (used by Jenkins/Kaniko)
    "ecr_region" = {
      name  = "ecr/region"
      value = local.aws_region
    }
    "ecr_repo_domain" = {
      name  = "ecr/repo_domain"
      value = split("/", module.ecr.repository_url)[0] # retains only the ecr domain <ecr domain>/<repo name>
    }
    "ecr_repo_name" = {
      name  = "ecr/repo_name"
      value = module.ecr.repository_name
    }
    "ecr_repo_url" = {
      name  = "ecr/repo_url"
      value = module.ecr.repository_url
    }

    # elastic
    "elastic_api_roles" = {
      name  = "elastic/superuser"
      value = "superuser" # pending move to argo-apps/elastic/secrets.yaml as "merge" in ExternalSecret
    }
    "elastic_api_password" = {
      name  = "elastic/api/password"
      value = random_password.elastic_password.result
    }
    "elastic_api_username" = {
      name  = "elastic/api/username"
      value = "elastic" # pending move to argo-apps/elastic/secrets.yaml as "merge" in ExternalSecret
    }

    # external-secrets
    "external_secrets_iam_role_arn" = {
      name  = "externam_secrets/iam/role_arn"
      value = aws_iam_role.external_secrets.arn
    }

    # grafana
    "grafana_admin_user" = {
      name  = "grafana/admin/username"
      value = "admin"
    }
    "grafana_admin_password" = {
      name  = "grafana/admin/password"
      value = random_password.grafana_password.result
    }

    # jenkins
    "jenkins_admin_username" = {
      name  = "jenkins/admin/username"
      value = "admin"
    }
    "jenkins_admin_password" = {
      name  = "jenkins/admin/password"
      value = random_password.jenkins_password.result
    }
    "jenkins_github_username" = {
      name  = "jenkins/github/username"
      value = var.ARGOCD_GITHUB_USER # not yet setup since repo is public
    }
    "jenkins_github_token" = {
      name  = "jenkins/github/token"
      value = var.ARGOCD_GITHUB_TOKEN # not yet setup since repo is public
    }
    "jenkins_iam_role_arn" = {
      name  = "jenkins/iam/role_arn"
      value = aws_iam_role.jenkins.arn
    }

    # prometheus
    "prometheus_iam_role_arn" = {
      name  = "prometheus/iam/role_arn"
      value = aws_iam_role.prometheus.arn
    }

    # sonarquebe
    "sonar_admin_password" = {
      name  = "sonar/admin/password"
      value = random_password.sonarqube_admin_password.result
    }
    "sonar_admin_password_current" = {
      name  = "sonar/admin/password_current"
      value = random_password.sonarqube_admin_password.result
    }
    "sonar_db_name" = {
      name  = "sonar/db/name"
      value = local.sonar_rds_dbname
    }
    "sonar_db_host" = {
      name  = "sonar/db/host"
      value = "jdbc:postgresql://${module.db_sonarqube.db_instance_endpoint}/${local.sonar_rds_dbname}" # `SONARQUBE_JDBC_URL` requires baked in interpolation # jdbc:postgresql://[host]:[port]/[database]
    }
    "sonar_db_port" = {
      name  = "sonar/db/port"
      value = local.sonar_rds_port
    }
    "sonar_db_user" = {
      name  = "sonar/db/username"
      value = local.sonar_rds_user
    }
    "sonar_db__password" = {
      name  = "sonar/db/password"
      value = random_password.sonarqube_database_password.result
    }
    "sonar_db_token" = {
      name  = "sonar/db/token"
      value = random_password.sonarqube_token.result
    }
  }

  tags = {
    Example = local.name
  }
}

###############################################################################
# Providers
###############################################################################

provider "aws" {
  region = var.aws_region
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}


###############################################################################
# SSM Parameter
###############################################################################

# Store secrets as SSM Parameters, that will be used by Kustomize via External Secrets Operator to dynamically inject secrets into pods

module "ssm-parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.2"

  for_each = local.parameters

  name            = lookup(each.value, "name", each.value.key)
  value           = lookup(each.value, "value", null)
  values          = lookup(each.value, "values", [])
  type            = lookup(each.value, "type", null)
  secure_type     = lookup(each.value, "secure_type", null)
  description     = lookup(each.value, "description", null)
  tier            = lookup(each.value, "tier", null)
  key_id          = lookup(each.value, "key_id", null)
  allowed_pattern = lookup(each.value, "allowed_pattern", null)
  data_type       = lookup(each.value, "data_type", null)

  depends_on = [
    module.eks,
  ]
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name             = local.name
  cluster_version          = var.cluster_version
  cluster_ip_family        = "ipv4"
  iam_role_use_name_prefix = true
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  create_cloudwatch_log_group = false
  cloudwatch_log_group_class  = "INFREQUENT_ACCESS"

  enable_irsa = true

  enable_cluster_creator_admin_permissions = true # # To add the current caller identity as an administrator

  create_kms_key            = false
  cluster_encryption_config = {}

  cluster_addons = {
    coredns = {
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      addon_version               = "v1.11.1-eksbuild.9"
      configuration_values = jsonencode({
        nodeSelector = {
          "role" = "core"
        }
      })
    }
    kube-proxy = {
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      addon_version               = "v1.29.3-eksbuild.2"
    }
    vpc-cni = {
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      addon_version               = "v1.18.1-eksbuild.3"
      before_compute              = true # Attempts to create VPC CNI before the associated nodegroups, EC2 bootstrap may still be needed
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true" # Increase max pods per node, t3.medium from 17 to 110 pod limit
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    aws-ebs-csi-driver = { # # pending `kubectl annotate sc gp2 storageclass.kubernetes.io/is-default-class: "false"`
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn    = module.ebs_csi_driver_irsa.iam_role_arn
      addon_version               = "v1.30.0-eksbuild.1" # v1.6.2-eksbuild.0
      configuration_values = jsonencode({
        #        storageClasses = [
        #          {
        #            name = "gp2"
        #            annotations = {
        #              "storageclass.kubernetes.io/is-default-class" = "false"
        #            }
        #          }
        #        ]
        sidecars : { # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/issues/1447 # fix `failed to list *v1.VolumeSnapshotClass` error
          snapshotter : {
            forceEnable : false
          }
        }

      })
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64" # This is custom AMI, `enable_bootstrap_user_data` must be set to True (ami_id not ami_type)
    instance_types = ["t3.medium"]
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Enable node to node communication
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_self_all = { # already created by module
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }
    # Control plane to nodes
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_groups = {

    # core infra - cicd
    core = {
      name        = "core-node-group"
      description = "Core managed node group launch template"

      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 2
      desired_size = 1

      ami_type       = "AL2_x86_64"
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      labels = {
        role = "core"
      }

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 30
            volume_type = "gp3"
            encrypted   = false
            #kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "core-managed-node-group-role"
      iam_role_use_name_prefix = false
      iam_role_description     = "core Managed node group role"
      iam_role_tags = {
        Purpose = "core-managed-node-group-role-tag"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      launch_template_tags = {
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }

      tags = {
        ExtraTag = "core-node"
      }
    }

    # app - django
    django = {
      name        = "django-node-group"
      description = "Django managed node group launch template"

      subnet_ids = module.vpc.private_subnets

      min_size     = 1
      max_size     = 3
      desired_size = 1

      ami_type       = "AL2_x86_64" # AL2_ARM_64 for arm
      instance_types = ["t3.large"] # Overrides default instance defined above
      capacity_type  = "SPOT"

      labels = {
        role = "django" # used by k8s/argocd. node selection, scheduling, grouping, policy enforcement
      }

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false
      #cloudwatch_log_group_class = "INFREQUENT_ACCESS"

      block_device_mappings = {
        xvdb = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size = 30
            volume_type = "gp3"
            encrypted   = false
            #kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "django-managed-node-group-role"
      iam_role_use_name_prefix = false
      iam_role_description     = "django managed node group role"
      iam_role_tags = {
        Purpose = "django-managed-node-group-role-tag"
      }
      iam_role_additional_policies = {
        # node wide policies
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Enable SSM
      }

      launch_template_tags = {
        # enable discovery of autoscaling groups by cluster-autoscaler
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }

      tags = {
        ExtraTag = "django-node" # used for cost allocation, resource mgmt, automation
      }
    }
  }

  access_entries = {
    argocdrepo = {
      principal_arn     = aws_iam_role.argocd_repo.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # cert-manager = {
    #   principal_arn     = aws_iam_role.cert_manager.arn
    #   kubernetes_groups = []
    # 
    #   policy_associations = {
    #     admin_policy = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #       access_scope = {
    #         type = "cluster"
    #       }
    #     }
    #   }
    # }

    django = {
      principal_arn     = aws_iam_role.django.arn
      kubernetes_groups = []

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    eck-operator = {
      principal_arn     = aws_iam_role.elastic_operator.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    eck-operator2 = {
      principal_arn     = aws_iam_role.elastic_operator2.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    external-dns = {
      principal_arn     = aws_iam_role.external_dns.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    external-secrets = {
      principal_arn     = aws_iam_role.external_secrets.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    imageupdater = { # argocd image updater
      principal_arn     = aws_iam_role.argocd_image_updater.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    fluent-operator = {
      principal_arn     = aws_iam_role.fluent_operator.arn # aws_iam_role.fluent_operator.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    fluent-operator2 = {                                    # change for fluent-bit
      principal_arn     = aws_iam_role.fluent_operator2.arn # aws_iam_role.fluent_operator.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    jenkins = {
      principal_arn     = aws_iam_role.jenkins.arn
      kubernetes_groups = []

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    prometheus = {
      principal_arn     = aws_iam_role.prometheus.arn
      kubernetes_groups = []

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    sonarqube = {
      principal_arn     = aws_iam_role.sonarqube.arn # aws_iam_role.fluent_operator.arn
      kubernetes_groups = []

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

## automation
#resource "aws_iam_role" "this" {
#  for_each = toset(["argocd", "jenkins", "alertmanager", "kubestatemetrics", "nodexporter", "grafana", "prometheus", "prometheusoperator"])
#
#  name = each.key
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Sid    = "Example"
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      },
#    ]
#  })
#
#  tags = local.tags
#}

###############################################################################
# STS - ServiceAccount/IRSA
###############################################################################

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    sid    = "EKSAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com"
      ]
    }
  }
}

# argocd
data "aws_iam_policy_document" "argocd_repo_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ArgoCDRepoAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:argocd:argo-cd-argocd-repo-server" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "argocd_repo" {
  name               = "ArgoCDrepoRole"
  assume_role_policy = data.aws_iam_policy_document.argocd_repo_assume_role_policy.json
}

# argocd image updater
data "aws_iam_policy_document" "argocd_image_updater_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ArgoCDImageUpdaterAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:argocd:argocd-image-updater" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "ImageUpdaterRole"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater_assume_role_policy.json
}

# django
data "aws_iam_policy_document" "django_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "DjangoAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:django:django" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "django" {
  name               = "DjangoRole"
  assume_role_policy = data.aws_iam_policy_document.django_assume_role_policy.json
}

# elastic - eck-pass
data "aws_iam_policy_document" "elastic_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ECKPassAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:eck-stack:eck-pass" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "elastic_operator" {
  name               = "ElasticRole"
  assume_role_policy = data.aws_iam_policy_document.elastic_assume_role_policy.json
}

# elastic = elastic-operator
data "aws_iam_policy_document" "elastic2_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "ECKOperatorAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:eck-stack:eck-operator" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "elastic_operator2" {
  name               = "ElasticRole2"
  assume_role_policy = data.aws_iam_policy_document.elastic2_assume_role_policy.json
}

# external secrets
resource "aws_iam_role" "external_secrets" {
  name               = "PrometheusRole"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

# fluent-operator
data "aws_iam_policy_document" "fluent_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "SonarqubeAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:fluent:fluent-operator" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "fluent_operator" {
  name               = "FluentRole"
  assume_role_policy = data.aws_iam_policy_document.fluent_assume_role_policy.json
}

# fluent-bit
data "aws_iam_policy_document" "fluentbit_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "SonarqubeAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:fluent:fluent-bit" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "fluent_operator2" {
  name               = "FluentRole2"
  assume_role_policy = data.aws_iam_policy_document.fluentbit_assume_role_policy.json
}

# jenkins
data "aws_iam_policy_document" "jenkins_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "JenkinsAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:jenkins:jenkins" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "JenkinsRole"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role_policy.json
}

# prometheus
data "aws_iam_policy_document" "prometheus_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "PrometheusAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:prometheus:kube-prometheus-stack-grafana" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "prometheus" {
  name               = "PrometheusRole"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role_policy.json
}

# sonarqube
data "aws_iam_policy_document" "sonarqube_assume_role_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.eks_assume_role_policy.json
  ]

  statement {
    sid    = "SonarqubeAssumeRoleWithWebIdentity"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        module.eks.oidc_provider_arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:sonarqube:sonarqube" # "namespace:service-account-name"
      ]
    }
  }
}

resource "aws_iam_role" "sonarqube" {
  name               = "SonarqubeRole"
  assume_role_policy = data.aws_iam_policy_document.sonarqube_assume_role_policy.json
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = local.name
  cidr = var.vpc_cidr

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]      # ~4k IPs
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)] # ~256 IPs
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)] # ~256 IPs

  #intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)] # used for control_plane_subnet_ids cluster (?)

  create_database_subnet_group = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true # needed for EFS
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # required for load balancer controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1 # required for load balancer controller
  }

  tags = local.tags
}

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${local.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}

################################################################################
# Permissions
################################################################################
## https://www.youtube.com/watch?v=kRKmcYC71J4
## Role for other user/team members to assume. get access to cluster
#module "allow_eks_access_iam_policy" {
#  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
#  version       = "5.3.1"
#  name          = "allow-eks-access"
#  create_policy = true
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "eks:DescribeCluster",
#        ]
#        Effect   = "ALLow"
#        Resource = "*"
#      },
#    ]
#  })
#}
#
## Role for other user/team members to assume. get access to cluster
#module "eks_admins_iam_role" {
#  source                  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#  version                 = "5.3.1"
#  role_name               = "eks-admin" # full access to kubernetes API
#  create_role             = true
#  role_requires_mfa       = false
#  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn] # attach policy above
#  trusted_role_arns = [
#    "arn:aws:iam::${module.vpc.vpc_owner_id}:root" # allow any user in account to assume role
#  ]
#}
#
## Create users
#module "user1_iam_user" {
#  source                        = "terraform-aws-modules/iam/aws//modules/iam-user"
#  version                       = "5.3.1"
#  name                          = "user1"
#  create_iam_access_key         = false
#  create_iam_user_login_profile = false
#  force_destroy                 = true
#}
#
## Allow assume
#module "allow_assume_eks_admin_iam_policy" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#  version = "5.3.1"
#  name    = "allow-assume-eks-admin-iam-role"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "sts:AssumeRole",
#        ]
#        Effect   = "ALLow"
#        Resource = module.eks_admins_iam_role.iam_role_arn
#      },
#    ]
#  })
#}
#
## Create group, add user to group
#module "eks_admins_iam_group" {
#  source                            = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
#  version                           = "5.3.1"
#  name                              = "eks-admin"
#  attach_iam_self_management_policy = false
#  create_group                      = true
#  group_users                       = [module.user1_iam_user.iam_user_name]
#  custom_group_policy_arns          = [module.allow_assume_eks_admin_iam_policy.arn]
#}

# Node SG
resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-remote-access"
  description = "Allow Remote Web and SSH access"
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_tcp_22" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Ingress Allow TCP Port 22 - SSH"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/8"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_tcp_8080" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Ingress Allow TCP Port 8080 - ArgoCD HTTP"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/8"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_tcp_8081" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Ingress Allow TCP Port 8081 - ArgoCD HTTPS"

  from_port   = 8081
  to_port     = 8081
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/8"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_tcp_80" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Ingress Allow TCP Port 80 - HTTP"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/8"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_allow_tcp_443" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Ingress Allow TCP Port 443 - HTTPS"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "10.0.0.0/8"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

resource "aws_vpc_security_group_egress_rule" "egress_allow_all" {
  security_group_id = aws_security_group.remote_access.id
  description       = "Egress Allow All"

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(
    local.tags,
    { Name = "${local.name}-remote" }
  )
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "ec2:*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "node_additional" {
  name        = "${local.name}-additional"
  description = "Example usage of node additional policy"
  policy      = data.aws_iam_policy_document.ec2_policy.json

  tags = local.tags
}

data "aws_ami" "eks_default" { # Retrieve the latest EKS optimized AMI
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

###############################################################################
# Load balancer
###############################################################################

# by default ALB creates one per ingress, to combine use annotation
# alb.ingress.kubernetes.io/group.name: django-production

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  role_name                              = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    sts = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Load balancer controller uses tags to discover subnets in which it can in which in can create load balancers
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.11.0"

  set {
    name  = "replicaCount" # by default it creates 2 replicas
    value = 1
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" # annotation to allows service account to assume aws role
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }

  values = [
    <<-EOF
    nodeSelector:
      role: "core"
    EOF
  ]

  depends_on = [
    module.aws_load_balancer_controller_irsa_role,
    module.eks
  ]
}

################################################################################
# EBS CSI Driver
################################################################################

# Create iam role for service account for the block device
# IAM additional policy https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2826
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  # create_role      = false
  role_name_prefix = "${module.eks.cluster_name}-ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# Enable gp3 for aws-ebs-csi-driver
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      # Annotation to set gp3 as default storage class
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    encrypted = false
    fsType    = "ext4"
    type      = "gp3"
  }

  depends_on = [
    module.eks
  ]
}

# Disable GP2 as default to prevent conflicts
# Pending on a cleaner way to do this within the EKS module, or tf resource
resource "null_resource" "update_gp2" {
  triggers = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
  }
  provisioner "local-exec" {
    command = "kubectl annotate sc gp2 storageclass.kubernetes.io/is-default-class=false --overwrite"
  }
  depends_on = [
    null_resource.update_kubeconfig
  ]
}


###############################################################################
# ECR
###############################################################################

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  repository_name = local.name

  repository_read_write_access_arns = [aws_iam_role.jenkins.arn] # pending . not attaching policy # depends on not set!!! arns could be list, # pending
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true

  tags = local.tags

  depends_on = [
    module.eks,
  ]
}

# Jenkins is going to push images to ECR
data "aws_iam_policy_document" "ecr_read_write_policy" {
  statement {
    sid    = "ECRReadWrite"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_read_write_policy" {
  name        = "ECRReadWritePolicy"
  description = "Allows ECR Get and Put permissions"
  path        = "/"
  policy      = data.aws_iam_policy_document.ecr_read_write_policy.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy_attach" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.ecr_read_write_policy.arn
}

# ArgoCD Image Updater is going to read ECR
# https://github.com/argoproj/argo-cd/issues/8097
resource "aws_iam_role_policy_attachment" "imageupdater_ecr_policy_attach" {
  role       = aws_iam_role.argocd_image_updater.name
  policy_arn = aws_iam_policy.ecr_read_write_policy.arn
}

###############################################################################
# External Secrets Operator
###############################################################################

# external secret management system with a KMS plugin to encrypt Secrets stored in etcd # pending

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  chart      = "external-secrets"
  namespace  = "kube-system"
  repository = "https://charts.external-secrets.io"
  version    = "0.14.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  #If set external secrets are only reconciled in the provided namespace # pending
  #  set {
  #    name  = "scopedNamespace"
  #    value = #?
  #  }

  values = [
    <<-EOF
    global:
      nodeSelector:
        role: "core"
    serviceAccount:
      create: true
      name: "external-secrets"
    EOF
  ]

  depends_on = [
    helm_release.aws_load_balancer_controller,
    module.eks
  ]
}

# argocd
data "aws_iam_policy_document" "argocd_ssm_read_policy" {
  statement {
    sid    = "ArgoCDSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/aws/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/cluster/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/ecr/*"
    ]
  }
}

resource "aws_iam_policy" "argocd_ssm_read_policy" {
  name        = "ArgoCDSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.argocd_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "argocd_ssm_read_attach" {
  role       = aws_iam_role.argocd_repo.name
  policy_arn = aws_iam_policy.argocd_ssm_read_policy.arn
}

# argocd image updater
data "aws_iam_policy_document" "imageupdater_ssm_read_policy" {
  statement {
    sid    = "ArgoCDImageUpdaterSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/argo/cd/image_updater/*"
    ]
  }
}

resource "aws_iam_policy" "imageupdater_ssm_read_policy" {
  name        = "ArgoCDImageUpdaterSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.imageupdater_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "imageupdater_ssm_read_attach" {
  role       = aws_iam_role.argocd_image_updater.name
  policy_arn = aws_iam_policy.imageupdater_ssm_read_policy.arn
}

# django
data "aws_iam_policy_document" "django_ssm_read_policy" {
  statement {
    sid    = "DjangoSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/app/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/cluster/*"
    ]
  }
}

resource "aws_iam_policy" "django_ssm_read_policy" {
  name        = "DjangoSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.django_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "django_ssm_read_attach" {
  role       = aws_iam_role.django.name
  policy_arn = aws_iam_policy.django_ssm_read_policy.arn
}

# elastic eck-pass
data "aws_iam_policy_document" "elastic_ssm_read_policy" {
  statement {
    sid    = "ElasticSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/elastic/*"
    ]
  }
}

resource "aws_iam_policy" "elastic_ssm_read_policy" {
  name        = "ElasticSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.elastic_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "elastic_ssm_read_attach" {
  role       = aws_iam_role.elastic_operator.name
  policy_arn = aws_iam_policy.elastic_ssm_read_policy.arn
}

# fluent operator
data "aws_iam_policy_document" "fluent_ssm_read_policy" {
  statement {
    sid    = "FluentSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/elastic/*"
    ]
  }
}

resource "aws_iam_policy" "fluent_ssm_read_policy" {
  name        = "FluentSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.fluent_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "fluent_ssm_read_attach" {
  role       = aws_iam_role.fluent_operator.name
  policy_arn = aws_iam_policy.fluent_ssm_read_policy.arn
}

# fluent bit
resource "aws_iam_role_policy_attachment" "fluentbit_ssm_read_attach" {
  role       = aws_iam_role.fluent_operator2.name
  policy_arn = aws_iam_policy.fluent_ssm_read_policy.arn
}

# jenkins
data "aws_iam_policy_document" "jenkins_ssm_read_policy" {
  statement {
    sid    = "JenkinsSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/app/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/aws/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/ecr/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/jenkins/*"
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/sonar/*"
    ]
  }
}

resource "aws_iam_policy" "jenkins_ssm_read_policy" {
  name        = "JenkinsSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.jenkins_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm_read_attach" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_ssm_read_policy.arn
}

# prometheus
data "aws_iam_policy_document" "prometheus_ssm_read_policy" {
  statement {
    sid    = "PrometheusSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/grafana/*"
    ]
  }
}

resource "aws_iam_policy" "prometheus_ssm_read_policy" {
  name        = "PrometheusSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.prometheus_ssm_read_policy
}

resource "aws_iam_role_policy_attachment" "prometheus_ssm_read_attach" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_ssm_read_policy.arn
}

# sonarqube
data "aws_iam_policy_document" "sonarqube_ssm_read_policy" {
  statement {
    sid    = "SonarqubeSSMReadParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:ListTagsForResource",
    ]
    resources = [
      "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter/sonar/*"
    ]
  }
}

resource "aws_iam_policy" "sonarqube_ssm_read_policy" {
  name        = "SonarqubeSSMReadPolicy"
  description = ""
  path        = "/"
  policy      = data.aws_iam_policy_document.sonarqube_ssm_read_policy.json
}

resource "aws_iam_role_policy_attachment" "sonarqube_ssm_read_attach" {
  role       = aws_iam_role.sonarqube.name
  policy_arn = aws_iam_policy.sonarqube_ssm_read_policy.arn
}

###############################################################################
# TF Helpers
###############################################################################

## Update kubeconfig cluster name and region
resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${local.name} --region ${local.aws_region}"
  }
  depends_on = [
    module.eks
  ]
}

###############################################################################
# ExternalDNS
###############################################################################

## must be set before tf apply
# export TF_VAR_CFL_API_TOKEN=123example
# When using API Token authentication, the token should be granted Zone Read, DNS Edit privileges, and access to All zones

# optional: limit which Ingress objects are used as an ExternalDNS source via the ingress-class

## Pass CF API token to k8s Secret
# kubectl create secret generic cloudflare-api-key --from-literal=apiKey=123example -n kube-system
resource "kubectl_manifest" "cloudflare_api_key" { # pending. change name to token for clarity
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: kube-system
type: Opaque
data:
  apiToken: ${base64encode(var.CFL_API_TOKEN)}
  YAML

  depends_on = [
    #helm_release.aws_load_balancer_controller,
    module.eks
  ]
}

# if gets stuck, `terraform apply -target=helm_release.external_dns -auto-approve`
# `terraform taint helm_release.external_dns`
# `aws eks update-kubeconfig --name django-production9 --region us-west-2`
# `rm ~/.kube/config`
resource "helm_release" "external_dns" {
  name       = "external-dns"
  chart      = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "1.15.2"

  values = [
    <<-EOF
    nodeSelector:
      role: "core"

    env:
    - name: CF_API_TOKEN
      valueFrom:
        secretKeyRef:
          name: cloudflare-api-token
          key: apiToken
    EOF
  ]

  #  set {
  #    name  = "extraArgs[0]" # API rate limit optimization
  #    value = "--cloudflare-dns-records-per-page=5000"
  #  }

  set {
    name  = "extraArgs[0]"
    value = "--source=ingress" # required for ALB
  }

  set {
    name  = "domainFilters[0]"
    value = local.domain # Necessary for helm install to succeed
  }

  set {
    name  = "provider.name"
    value = "cloudflare"
  }

  set {
    name  = "policy"
    value = "sync" # sync also deletes records. # upsert-only
  }

  set {
    name  = "txtOwnerId"
    value = local.name # cluster name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  set {
    name  = "serviceAccount.automountServiceAccountToken"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  depends_on = [
    kubectl_manifest.cloudflare_api_key
    #helm_release.aws_load_balancer_controller,
    #module.eks
  ]
}

resource "aws_iam_role" "external_dns" {
  name               = "external-dns"
  description        = ""
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

################################################################################
## Cert-Manager
################################################################################
# This can only be used with NLB currently, as AWS LBC only supports ACM certs. There is a feature request pending, so ALB use might be enabled soon.
## DNS01 validation was used since it's needed when CI/CD apps are not publicly accessible
#
##resource "kubernetes_namespace" "cert_manager" {
##  metadata {
##    name = "cert-manager"
##  }
##}
#
#resource "kubectl_manifest" "cert_manager" {
#  yaml_body = file("../../${path.module}/argo-apps/argocd/cert-manager.yaml")
#
#  depends_on = [
#    helm_release.cert_manager
#  ]
#}
#
#resource "helm_release" "cert_manager" {
#  name       = "cert-manager"
#  chart      = "cert-manager"
#  repository = "https://charts.jetstack.io"
#  namespace  = "cert-manager" #
#
#  #create_namespace = true
#
#  version    = "1.14.5"
#
#  values = [
#    <<-EOF
#    nodeSelector:
#      role: "core"
#
#    EOF
#  ]
#
#  set {
#    name  = "installCRDs" # although deprecated, install fails with only crds.enabled=true, both crds.enabled and crds.keep are needed
#    value = "true"
#  }
#
##  set {
##    name  = "crds.enabled" # decides if the CRDs should be installed
##    value = "true"
##  }
##  set {
##    name  = "crds.keep" # prevent Helm from uninstalling the CRD when the Helm release is uninstalled
##    value = "true"
##  }
#
#  set {
#    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#    value = aws_iam_role.cert_manager.arn
#  }
#
#  set {
#    name  = "serviceAccount.name"
#    value = "cert-manager"
#  }
#
#  #         extraArgs:
#  #          - --logging-format=json
#  #        webhook:
#  #          extraArgs:
#  #            - --logging-format=json
#  #        cainjector:
#  #          extraArgs:
#  #            - --logging-format=json
#
#
#  depends_on = [
#    helm_release.aws_load_balancer_controller,
#    module.eks
#  ]
#
#}
#
#resource "aws_iam_role" "cert_manager" {
#  name = "cert-manager"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Principal = {
#          Service = "eks.amazonaws.com"
#        }
#        Action = "sts:AssumeRole"
#      },
#    ]
#  })
#}

###############################################################################
# ACM
###############################################################################
# Load Balancer Controller only works with ACM certificates (and cert-manager can't issue ACM certs)
# added in release v2.8.0
# Support set the certificateArn for Ingress at the IngressClass level. This feature adds new certificateArn to the IngressClassParams Spec to configure the ARN of the certificates for all Ingresses that belong to IngressClass with this IngressClassParams.
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/ingress/cert_discovery/

resource "kubectl_manifest" "ingress_class_params" {
  yaml_body = <<-EOT
  apiVersion: elbv2.k8s.aws/v1beta1
  kind: IngressClassParams
  metadata:
    name: alb  # Ensure this matches the existing IngressClassParams name
  spec:
    certificateArn:
      - "${module.acm.acm_certificate_arn}"
  EOT

  depends_on = [
    helm_release.aws_load_balancer_controller,
    module.acm
  ]
}

## must be set before tf apply
# export TF_VAR_CFL_ZONE_ID=123example

# Create ACM wildcard cert, with DNS validation using Cloudflare
# if gets stuck `terraform apply -target=module.acm`
# `terraform taint module.acm`
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  # ACM cert for subdomains only
  domain_name = "*.${local.domain}" # only for subdomains of *.hansohn.io, TLD is not included by default
  zone_id     = var.CFL_ZONE_ID

  validation_method = "DNS"

  validation_record_fqdns = cloudflare_dns_record.validation[*].hostname

  wait_for_validation    = true
  create_route53_records = false

  #  subject_alternative_names = [
  #    "*.${local.domain}", # domain name and subject alternative name should not be repeated
  #  ]

  tags = {
    Name = local.domain
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
  ]
}

###############################################################################
# Cloudflare
###############################################################################
# This block only takes care of validating the wildcard ACM cert.
# individual app CNAME entries are created dynamically by ExternalDNS (defined in the ingress.yaml of each app)

## must be set before tf apply
# export TF_VAR_CFL_API_TOKEN=123example
# or have tfvars present

provider "cloudflare" {
  api_token = var.CFL_API_TOKEN
}

# Validate generated ACM cert by creating validation domain record
resource "cloudflare_dns_record" "validation" {
  count = length(module.acm.distinct_domain_names)

  zone_id = var.CFL_ZONE_ID
  name    = element(module.acm.validation_domains, count.index)["resource_record_name"]
  type    = element(module.acm.validation_domains, count.index)["resource_record_type"]
  content = trimsuffix(element(module.acm.validation_domains, count.index)["resource_record_value"], ".")
  ttl     = 60
  proxied = false


  depends_on = [
    helm_release.aws_load_balancer_controller,
  ]
}

###############################################################################
# RDS - django-app
###############################################################################

# Pending. connection pooling (possibly using something like django-db-connection-pool or other external tools like PgBouncer).
# Create rds random password.
resource "random_password" "database_password" {
  length           = 28
  special          = true
  override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

resource "random_password" "django_secretkey" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  # aws rds describe-db-engine-versions --default-only --engine postgres
  engine               = "postgres"
  engine_version       = "16.6"
  family               = "postgres16" # DB parameter group
  major_engine_version = "16"         # DB option group
  instance_class       = "db.t4g.micro"

  #kms_key_id        = "arn:aws:kms:${local.aws_region}:${var.account_id}:key/${data.aws_ssm_parameter.kms_keyid.value}"

  allocated_storage     = 5
  max_allocated_storage = 10

  db_name  = local.rds_dbname
  username = local.rds_user
  port     = local.rds_port

  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(60 days)"
  manage_master_user_password                       = false # Set to true to allow RDS to manage the master user password in Secrets Manager

  password = random_password.database_password.result
  #password = aws_ssm_parameter.rds_password.value # random_password.database_password.result # data.aws_ssm_parameter.kms_keyid.value
  # IRSA + IAM DB auth?

  iam_database_authentication_enabled = false # pending
  publicly_accessible                 = false

  multi_az = false # false
  #availability_zone = local.azs
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  create_db_option_group    = false # Use a default option group provided by AWS
  create_db_parameter_group = false # Use a default parameter group provided by AWS

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = false
  monitoring_interval                   = 0 # 0 disables collecting enhanced metrics
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [ # pending. force SSL?
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }

  depends_on = [
    module.eks,
    #helm_release.aws_load_balancer_controller,
  ]
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = local.name
  description = "Complete PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432 # pending local.rds_port
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

###############################################################################
# RDS - sonarqube
###############################################################################

# Pending. connection pooling (possibly using something like django-db-connection-pool or other external tools like PgBouncer).
# Create rds random password.
resource "random_password" "sonarqube_database_password" {
  length           = 28
  special          = true
  override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

resource "random_password" "sonarqube_admin_password" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

resource "random_password" "sonarqube_token" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

module "db_sonarqube" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "${local.name}-rds-sonar"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  # aws rds describe-db-engine-versions --default-only --engine postgres
  engine               = "postgres"
  engine_version       = "16.6"
  family               = "postgres16" # DB parameter group
  major_engine_version = "16"         # DB option group
  instance_class       = "db.t4g.micro"

  #kms_key_id        = "arn:aws:kms:${local.aws_region}:${var.account_id}:key/${data.aws_ssm_parameter.kms_keyid.value}"

  allocated_storage     = 5
  max_allocated_storage = 10

  db_name  = local.sonar_rds_dbname
  username = local.sonar_rds_user
  port     = local.sonar_rds_port

  manage_master_user_password_rotation              = false
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(60 days)"
  manage_master_user_password                       = false # Set to true to allow RDS to manage the master user password in Secrets Manager

  password = random_password.sonarqube_database_password.result
  #password = aws_ssm_parameter.rds_password.value # random_password.database_password.result # data.aws_ssm_parameter.kms_keyid.value
  # IRSA + IAM DB auth?

  iam_database_authentication_enabled = false # pending
  publicly_accessible                 = false

  multi_az = false # false
  #availability_zone = local.azs
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  create_db_option_group    = false # Use a default option group provided by AWS
  create_db_parameter_group = false # Use a default parameter group provided by AWS

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = false
  monitoring_interval                   = 0 # 0 disables collecting enhanced metrics
  monitoring_role_name                  = "sonarqube-example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "sonarqube Description for monitoring role"

  parameters = [ # pending. force SSL?
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    },
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }

  depends_on = [
    module.eks,
    #helm_release.aws_load_balancer_controller,
  ]
}

###############################################################################
# Generate Random Passwords
###############################################################################

## Create es random password.
resource "random_password" "elastic_password" {
  length           = 28
  special          = true
  override_special = "!$%&()+-?_~" # special character whitelist
}

## Jenkins
resource "random_password" "jenkins_password" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

## Grafana
resource "random_password" "grafana_password" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}

## ArgoCD
resource "random_password" "argocd_password" {
  length      = 28
  special     = false
  min_numeric = 10
  #override_special = "!#$%&'()+,-.=?^_~" # special character whitelist
}
