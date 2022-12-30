################################################################################
# EKS Module
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "hash_cluster"
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.24"
}

variable "coredns_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = "v1.8.7-eksbuild.3"
}
variable "kube_proxy_version" {
  description = "Version of the Kube Proxy addon"
  type        = string
  default     = "v1.23.8-eksbuild.2"
}
variable "vpc_cni_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = "v1.12.0-eksbuild.1"
}

variable "enabled_cluster_log_types" {

  description = "Types of EKS components to enable logs"
  type        = list(any)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch log retention perioid"
  type        = number
  default     = 30
}


variable "cluster_endpoint_public_access_cidrs" {
  description = "List of IP address ranges which can access API server publically"
  type        = list(any)
  default     = ["0.0.0.0/0"]

}

variable "envirnoment" {
  description = "Enviroment ex : Dev, Stage, Prod"
  type        = string
  default     = "dev"
}
variable "ingress_rules" {
  description = "Set of ingress IP address which allowed to access EKS manage node groups"
  type        = list(any)
  default = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}

