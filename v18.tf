# provider "aws" {
#   region = local.region
# }

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
#   }
# }

# locals {
#   name            = "migrate"
#   cluster_version = "1.21"
#   region          = "us-east-1"
# }

# ################################################################################
# # EKS Module
# ################################################################################

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "18.20.5"

#   cluster_name    = local.name
#   cluster_version = local.cluster_version

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = [module.vpc.private_subnets[0], module.vpc.public_subnets[1]]

#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   # Add to maintain v17 settings to avoid control plane replacement
#   prefix_separator                   = ""
#   iam_role_name                      = local.name
#   cluster_security_group_name        = local.name
#   cluster_security_group_description = "EKS cluster security group."

#   # # Worker groups (using Launch Configurations)
#   # worker_groups = [
#   #   {
#   #     name                          = "worker-group-1"
#   #     instance_type                 = "t3.small"
#   #     additional_userdata           = "echo foo bar"
#   #     asg_desired_capacity          = 2
#   #     additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
#   #   },
#   #   {
#   #     name                          = "worker-group-2"
#   #     instance_type                 = "t3.medium"
#   #     additional_userdata           = "echo foo bar"
#   #     additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
#   #     asg_desired_capacity          = 1
#   #   },
#   # ]

#   # Worker groups (using Launch Templates)
#   self_managed_node_group_defaults = {
#     vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
#   }

#   self_managed_node_groups = {
#     spot1 = {
#       name = "spot-1"

#       use_mixed_instances_policy = true
#       mixed_instances_policy = {
#         instances_distribution = {
#           on_demand_base_capacity                  = 0
#           on_demand_percentage_above_base_capacity = 0
#           spot_allocation_strategy                 = "lowest-price"
#         }
#         override = [
#           { instance_type = "m5.large" },
#           { instance_type = "m5a.large" },
#           { instance_type = "m5d.large" },
#           { instance_type = "m5ad.large" },
#         ]
#       }

#       max_size           = 5
#       desired_size       = 5
#       kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=spot"
#       # public_ip               = true
#     }
#   }

#   # Managed Node Groups
#   eks_managed_node_group_defaults = {
#     ami_type  = "AL2_x86_64"
#     disk_size = 50
#   }

#   eks_managed_node_groups = {
#     example = {
#       # Avoid replacement
#       name                     = "migrate-example20220503145931528500000018"
#       use_name_prefix          = false
#       iam_role_name            = "migrate2022050314593041360000000e"
#       iam_role_use_name_prefix = false

#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

#       instance_types = ["t3.large"]
#       capacity_type  = "SPOT"
#       labels = {
#         Environment = "test"
#         GithubRepo  = "terraform-aws-eks"
#         GithubOrg   = "terraform-aws-modules"
#       }

#       tags = {
#         ExtraTag = "example"
#       }

#       taints = [
#         {
#           key    = "dedicated"
#           value  = "gpuGroup"
#           effect = "NO_SCHEDULE"
#         }
#       ]

#       update_config = {
#         max_unavailable_percentage = 50 # or set `max_unavailable`
#       }
#     }
#   }

#   # Fargate
#   fargate_profile_defaults = {
#     subnet_ids = [module.vpc.private_subnets[2]]
#   }

#   fargate_profiles = {
#     default = {
#       name = "default"

#       selectors = [
#         {
#           namespace = "kube-system"
#           labels = {
#             k8s-app = "kube-dns"
#           }
#         },
#         {
#           namespace = "default"
#         }
#       ]

#       tags = {
#         Owner = "test"
#       }

#       timeouts = {
#         create = "20m"
#         delete = "20m"
#       }
#     }
#   }

#   # AWS Auth (kubernetes_config_map)
#   manage_aws_auth_configmap = true
#   aws_auth_roles = [
#     {
#       rolearn  = "arn:aws:iam::66666666666:role/role1"
#       username = "role1"
#       groups   = ["system:masters"]
#     },
#   ]

#   aws_auth_users = [
#     {
#       userarn  = "arn:aws:iam::66666666666:user/user1"
#       username = "user1"
#       groups   = ["system:masters"]
#     },
#     {
#       userarn  = "arn:aws:iam::66666666666:user/user2"
#       username = "user2"
#       groups   = ["system:masters"]
#     },
#   ]

#   aws_auth_accounts = [
#     "777777777777",
#     "888888888888",
#   ]

#   tags = {
#     Example    = local.name
#     GithubRepo = "terraform-aws-eks"
#     GithubOrg  = "terraform-aws-modules"
#   }
# }

# # ################################################################################
# # # Disabled creation
# # ################################################################################

# # module "disabled_eks" {
# #   source = "../.."

# #   create_eks = false
# # }

# # module "disabled_fargate" {
# #   source = "../../modules/fargate"

# #   create_fargate_pod_execution_role = false
# # }

# # module "disabled_node_groups" {
# #   source = "../../modules/node_groups"

# #   create_eks = false
# # }

# ################################################################################
# # Additional security groups for workers
# ################################################################################

# resource "aws_security_group" "worker_group_mgmt_one" {
#   name_prefix = "worker_group_mgmt_one"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"

#     cidr_blocks = [
#       "10.0.0.0/8",
#     ]
#   }
# }

# resource "aws_security_group" "worker_group_mgmt_two" {
#   name_prefix = "worker_group_mgmt_two"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"

#     cidr_blocks = [
#       "192.168.0.0/16",
#     ]
#   }
# }

# resource "aws_security_group" "all_worker_mgmt" {
#   name_prefix = "all_worker_management"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"

#     cidr_blocks = [
#       "10.0.0.0/8",
#       "172.16.0.0/12",
#       "192.168.0.0/16",
#     ]
#   }
# }

# ################################################################################
# # Supporting resources
# ################################################################################

# data "aws_availability_zones" "available" {}

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 3.0"

#   name                 = local.name
#   cidr                 = "10.0.0.0/16"
#   azs                  = data.aws_availability_zones.available.names
#   private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${local.name}" = "shared"
#     "kubernetes.io/role/elb"              = "1"
#   }

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${local.name}" = "shared"
#     "kubernetes.io/role/internal-elb"     = "1"
#   }

#   tags = {
#     Example    = local.name
#     GithubRepo = "terraform-aws-eks"
#     GithubOrg  = "terraform-aws-modules"
#   }
# }
