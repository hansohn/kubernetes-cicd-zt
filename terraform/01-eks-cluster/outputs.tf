#--------------------------------------------------------------
# AWS
#--------------------------------------------------------------

output "aws_account" {
  description = "Aws account"
  value       = data.aws_caller_identity.current.account_id
}

output "domain" {
  value       = local.domain
  description = "The name of domain"
}

output "name" {
  value       = local.name
  description = "Cluster name."
}

output "region" {
  value       = local.aws_region
  description = "The AWS region where the EKS cluster is deployed."
}

#--------------------------------------------------------------
# EKS
#--------------------------------------------------------------

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for the EKS cluster API. Required to configure kubectl."
}

output "eks" {
  value       = module.eks
  description = "The EKS module itself."
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "The certificate authority data for the EKS cluster."
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster."
}

output "access_entries" {
  value       = module.eks.access_entries
  description = "Security group entries that allow access to the EKS cluster."
}

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}


#--------------------------------------------------------------
# ECR
#--------------------------------------------------------------

output "ecr_repo_url" {
  value = split("/", module.ecr.repository_url)[0]
}

output "repository_name" {
  description = "Name of the repository"
  value       = module.ecr.repository_name
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = module.ecr.repository_arn
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = module.ecr.repository_registry_id
}

output "repository_url" {
  description = "The URL of the repository (in the form `aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName`)"
  value       = module.ecr.repository_url
}

#--------------------------------------------------------------
# ArgoCD
#--------------------------------------------------------------

output "argo_cd_imageupdater_iam_role_arn" {
  value = aws_iam_role.argocd_image_updater.arn
}

output "argo_cd_aws_domain" {
  value = local.domain
}

output "argo_cd_repo_iam_role_arn" {
  value = aws_iam_role.argocd_repo.arn
}

#--------------------------------------------------------------
# Jenkins
#--------------------------------------------------------------

output "jenkins_iam_role_arn" {
  value = aws_iam_role.jenkins.arn
}

#--------------------------------------------------------------
# Prometheus
#--------------------------------------------------------------

output "prometheus_iam_role_arn" {
  value = aws_iam_role.prometheus.arn
}

#--------------------------------------------------------------
# External Secrets
#--------------------------------------------------------------

output "external_secrets_iam_role_arn" {
  value = aws_iam_role.external_secrets.arn
}

#--------------------------------------------------------------
# Django
#--------------------------------------------------------------

output "django_iam_role_arn" {
  value = aws_iam_role.django.arn
}

#--------------------------------------------------------------
# Certificates
#--------------------------------------------------------------

output "distinct_domain_names" {
  description = "List of distinct domains names used for the validation."
  value       = module.acm.distinct_domain_names
}

output "validation_domains" {
  description = "List of distinct domain validation options. This is useful if subject alternative names contain wildcards."
  value       = module.acm.validation_domains
}

#--------------------------------------------------------------
# RDS
#--------------------------------------------------------------

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = split(":", module.db.db_instance_endpoint)[0] # regular output includes `endpoint:port`, this filters out the port
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = module.db.db_instance_engine_version_actual
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.db.db_instance_hosted_zone_id
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db.db_instance_identifier
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}

#--------------------------------------------------------------
# SonarQube
#--------------------------------------------------------------

output "db_sonar_instance_endpoint" {
  description = "The connection endpoint"
  value       = split(":", module.db_sonarqube.db_instance_endpoint)[0] # regular output includes `endpoint:port`, this filters out the port
}
