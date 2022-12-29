################################################################################
# EKS Module
################################################################################

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  #Cluster primary inputs
  cluster_name                   = var.cluster_name
  cluster_version = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true


  #Monitoring
  cluster_enabled_log_types = var.enabled_cluster_log_types
  create_cloudwatch_log_group = true
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  #Service account and Roles
  enable_irsa = true


  #Networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets


  #Cluster Addons
  cluster_addons = {

    coredns = {
      addon_version = var.coredns_version

    }

    kube-proxy = {
      addon_version = var.kube_proxy_version
    }
    
    vpc-cni = {
      addon_version = var.vpc_cni_version
    }
  }


################################################################################
# EKS Managed Node Groups
################################################################################


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium", "t3.large"]

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.additional.id]
    iam_role_additional_policies = {
      additional = aws_iam_policy.additional.arn
    }
  }


  #Node which use to deploy applications related workloads
  eks_managed_node_groups = {
    app_node = {

      min_size     = 1
      max_size     = 10
      desired_size = 1
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      labels = {
        Environment = var.envirnoment
        GithubRepo  = "helm_configs"
      }

      update_config = {
        max_unavailable_percentage = 10 # or set `max_unavailable`
      }

      tags = {
        NodeType = "System"
      }


    }




    #Node which use to deploy system related workloads
    system_node = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      labels = {
        Environment = var.envirnoment
        GithubRepo  = "terraform-aws-eks"
      }
      
      # Add taint to schedule only workload which tolarate 
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "system"
          effect = "NO_SCHEDULE"
        }
      }

      update_config = {
        max_unavailable_percentage = 10 # or set `max_unavailable`
      }

      tags = {
        NodeType = "System"
      }
    }
  }
################################################################################
# Cluster Security
################################################################################

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }



################################################################################
# EKS Encryption
################################################################################

  # External encryption key
#   create_kms_key = true
#   cluster_encryption_config = {
#     resources        = ["secrets"]
#     provider_key_arn = module.kms.key_arn
#   }

#   iam_role_additional_policies = {
#     additional = aws_iam_policy.additional.arn
#   }




################################################################################
# EKS Authenticaion
################################################################################


  # aws-auth configmap
#   manage_aws_auth_configmap = true

#   aws_auth_node_iam_role_arns_non_windows = [
#     module.eks_managed_node_group.iam_role_arn
#   ]


#   aws_auth_roles = [
#     {
#       rolearn  = module.eks_managed_node_group.iam_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups = [
#         "system:bootstrappers",
#         "system:nodes",
#       ]
#     }
#   ]

  tags = local.tags
}


################################################################################
# Supporting resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = merge(local.tags, { Name = "${local.name}-additional" })
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}