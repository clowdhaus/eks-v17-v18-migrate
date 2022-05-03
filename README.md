## Control Plane Changes

Execute the following after changing the module version and executing `terraform init -upgrade=true`

⚠️ If you run a `terraform plan` at this time it will fail!

1. Add the following settings to avoid disruption to control plane. These settings carry forward v17.x values to avoid disruptive replacement:

```hcl
  prefix_separator                   = ""
  iam_role_name                      = $CLUSTER_NAME
  cluster_security_group_name        = $CLUSTER_NAME
  cluster_security_group_description = "EKS cluster security group."
```

⚠️ If you run a `terraform plan` at this time it will fail!

2. Rename cluster IAM role resource using a Terraform state move

```
terraform state mv 'module.eks.aws_iam_role.cluster[0]' 'module.eks.aws_iam_role.this[0]'
```

✅ You now can run a plan!

3. Update control plane resources

terraform apply -target 'module.eks.aws_iam_role.this[0]'
terraform apply -target 'module.eks.aws_eks_cluster.this[0]'
terraform apply -target 'module.eks.aws_eks_cluster.this[0]' -refresh-only # clean up plan

## Data Plane Changes

### Fargate Profiles

```
terraform state mv 'module.eks.module.fargate.aws_iam_role.eks_fargate_pod[0]' 'module.eks.module.fargate_profile["default"].aws_iam_role.this[0]'
terraform state mv 'module.eks.module.fargate.aws_eks_fargate_profile.this["default"]' 'module.eks.module.fargate_profile["default"].aws_eks_fargate_profile.this[0]'
terraform state mv 'module.eks.module.fargate.aws_iam_role_policy_attachment.eks_fargate_pod[0]' 'module.eks.module.fargate_profile["default"].aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"]'
```

### EKS Managed Node Groups

```
terraform state mv 'module.eks.module.node_groups.aws_eks_node_group.workers["example"]' 'module.eks.module.eks_managed_node_group["example"].aws_eks_node_group.this[0]'
terraform state mv 'module.eks.aws_iam_role.workers[0]' 'module.eks.module.eks_managed_node_group["example"].aws_iam_role.this[0]'
```

### Self Managed Node Groups

```
terraform state mv 'module.eks.aws_launch_template.workers_launch_template[0]' 'module.eks.module.self_managed_node_group["spot1"].aws_launch_template.this[0]'
terraform state mv 'module.eks.aws_autoscaling_group.workers_launch_template[0]' 'module.eks.module.self_managed_node_group["spot1"].aws_autoscaling_group.this[0]'
terraform state mv 'module.eks.aws_iam_instance_profile.workers_launch_template[0]' 'module.eks.module.self_managed_node_group["spot1"].aws_iam_instance_profile.this[0]'
```

## Misc

- `module.eks.local_file.kubeconfig[0]` will be destroyed, users can use `aws eks update-kubeconfig --name <cluster-name>`
