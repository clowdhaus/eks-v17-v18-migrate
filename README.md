
- `worker_groups` are destroy only because they are backed by launch configurations and launch configuration is no longer supported in the module, only launch templates


- `fargate_subnets` top level variable is now moved to `subnet_ids` under the `fargate_profiles` or `fargate_profile_defaults`

- `subnets` -> `subnet_ids`

## EKS Managed Node Groups

- `node_groups` -> `eks_managed_node_groups`
- `node_groups_defaults` -> `eks_managed_node_groups_defaults`
- `k8s_labels` -> `labels`
- `additional_tags` -> `tags`
- `min_capacity` -> `min_size`
- `max_capacity` -> `max_capacity`
- `desired_capacity` -> `desired_size`

## Self Manageed Node Groups

- `override_instance_types` -> not supported
- `spot_instance_pools` -> ???
- `asg_max_size` -> `max_size`
- `asg_desired_capacity` -> `desired_size`
- `worker_additional_security_group_ids` -> `vpc_security_group_ids`

## `aws-auth` Configmap

- `map_roles` -> `aws_auth_roles`
- `map_users` -> `aws_auth_users`
- `map_accounts` -> `aws_auth_accounts`

## Changes

:warning: If you run a `terraform plan` at this time it will fail!

1. Set v17.x settings to avoid disruption to control plane:

```
  prefix_separator                   = ""
  iam_role_name                      = $CLUSTER_NAME
  cluster_security_group_name        = $CLUSTER_NAME
  cluster_security_group_description = "EKS cluster security group."
```

:warning: If you run a `terraform plan` at this time it will fail!

2. Rename cluster role resource by state move

`terraform state mv 'module.eks.aws_iam_role.cluster[0]' 'module.eks.aws_iam_role.this[0]'`


:green-check: You now can run a plan!

3. Update control plane resources
tf apply -target 'module.eks.aws_iam_role.this[0]'
tf apply -target 'module.eks.aws_eks_cluster.this[0]'
tf apply -target 'module.eks.aws_eks_cluster.this[0]' -refresh-only # clean up plan

# Fargate Profiles
tf apply -target 'module.eks.module.fargate_profile["default"]'
- or -
tf state rm 'module.eks.module.fargate_profile["default"].aws_eks_fargate_profile.this[0]'
tf state rm 'module.eks.module.fargate_profile["default"].aws_iam_role.this[0]'
tf apply -target 'module.eks.module.fargate_profile["default"]'
Then go and manually add a taint to the old profile, delete the pods to move to new profile, then delete old IAM role and profile

# Self Managed Node Groups
Create new node groups first
tf apply -target 'module.eks.module.self_managed_node_group["spot1"]'

# EKS Managed Node Groups
Create new node groups first
tf apply -target 'module.eks.module.eks_managed_node_group["example"]'

## Misc

- `module.eks.local_file.kubeconfig[0]` will be destroyed, users can use `aws eks update-kubeconfig --name <cluster-name>`
- Fargate profile role will be re-created regardless due to prior hardcoding of `name_prefix` using `cluster_name` plus the prefix separator addition

# EKS Managed Node Groups
terraform state mv 'module.eks.module.node_groups.aws_eks_node_group.workers["example"]' 'module.eks.module.eks_managed_node_group["example"].aws_eks_node_group.this[0]'

# Fargate Profiles
terraform state mv 'module.eks.module.fargate.aws_eks_fargate_profile.this["default"]' 'module.eks.module.fargate_profile["default"].aws_eks_fargate_profile.this[0]'
terraform state mv 'module.eks.module.fargate.aws_iam_role.eks_fargate_pod[0]' 'module.eks.module.fargate_profile["default"].aws_iam_role.this[0]'

