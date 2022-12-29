################################################################################
# EKS Module
################################################################################

variable "cluster_name" {
    description = "Name of the EKS cluster"
    type = string
}

variable "cluster_version" {
    description = "Version of the EKS cluster"
    type = string
    default = "1.24"
}

variable "coredns_version" {
    description = "Version of the CoreDNS addon"
    type = string
    default = "value"
  }
variable "kube_proxy_version" {
  description = "Version of the Kube Proxy addon"
  type = string
  default = "value"
}
variable "vpc_cni_version" {
    description= "Version of the VPC CNI addon"
    type = string
    default = "value"
}

variable "enabled_cluster_log_types" {
    
    description = "EKS components to enable logs"
    type = list
    default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

