#--------------------------------------------------------------
# AWS
#--------------------------------------------------------------

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region to deploy resources"
}

#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
}

#--------------------------------------------------------------
# EKS
#--------------------------------------------------------------

variable "cluster_version" {
  type        = string
  default     = "1.32"
  description = ""
}

variable "TF_ENVIRONMENT" {
  description = "Environment"
  type        = string
}

variable "TF_DOMAIN" {
  description = "Cluster domain name"
  type        = string
}

variable "TF_REPO_URL" {
  description = "Cluster repo"
  type        = string
}

variable "TF_REGION" {
  description = "Cluster region"
  type        = string
}

#--------------------------------------------------------------
# ArgoCD
#--------------------------------------------------------------

variable "ARGOCD_GITHUB_TOKEN" {
  description = "ArgoCD Image Updater Github Personal Token"
  type        = string
  sensitive   = true
}

variable "ARGOCD_GITHUB_USER" {
  description = "ArgoCD Image Updater Github username"
  type        = string
  sensitive   = true
}

#--------------------------------------------------------------
# Cloudfkare
#--------------------------------------------------------------

variable "CFL_API_TOKEN" {
  description = "API token for Cloudflare"
  type        = string
  sensitive   = true
}

variable "CFL_ZONE_ID" {
  description = "Zone ID for Cloudflare"
  type        = string
  sensitive   = true
}
