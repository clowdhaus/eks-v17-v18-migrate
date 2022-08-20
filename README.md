## Before You Begin

The steps proposed here are merely that - one proposal to an upgrade path from v17 to v18. The steps below are setup to preserve the control plane and data plane, however, the existing data plane will be ejected from Terraform control to avoid any service disruption. Currently, there are no paths for upgrading the data plane in-place that do not pose a risk of potential downtime. Therefore, the steps outlined here are designed to avoid downtime by following a blue/green approach to upgrading the data plane. The existing (v17) data plane components are ejected from Terraform control which allows for new (v18) data plane components to be deployed alongside the previous version components. Once the new (v18) data plane components are provisioned, users can start to cordon and drain the previous (v17) data plane components, scale them down, and finally remove entirely from AWS.

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

```sh
terraform state mv 'module.eks.aws_iam_role.cluster[0]' 'module.eks.aws_iam_role.this[0]'
```

✅ You now can run a plan!

3. Update control plane resources

```sh
terraform apply -target 'module.eks.aws_iam_role.this[0]'
terraform apply -target 'module.eks.aws_eks_cluster.this[0]'
terraform apply -target 'module.eks.aws_eks_cluster.this[0]' -refresh-only
```

## Data Plane Changes

### "Workers"

The following commands will remove the shared "workers" IAM role and security group from Terraform control. Users will need to be clean up these resources manually after the migration has completed (once they are no longer utilized by any data plane resources).

```sh
terraform state rm 'module.eks.aws_iam_role.workers[0]'
terraform state rm 'module.eks.aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy[0]'
terraform state rm 'module.eks.aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy[0]'
terraform state rm 'module.eks.aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly[0]'

terraform state rm 'module.eks.aws_security_group.workers[0]'
terraform state rm 'module.eks.aws_security_group_rule.workers_ingress_self[0]'
terraform state rm 'module.eks.aws_security_group_rule.workers_ingress_cluster_https[0]'
terraform state rm 'module.eks.aws_security_group_rule.workers_ingress_cluster[0]'
terraform state rm 'module.eks.aws_security_group_rule.workers_egress_internet[0]'
terraform state rm 'module.eks.aws_security_group_rule.cluster_https_worker_ingress[0]'
terraform state rm 'module.eks.aws_security_group_rule.cluster_egress_internet[0]'
```

### Fargate Profiles

```sh
terraform state rm 'module.eks.module.fargate.aws_iam_role.eks_fargate_pod[0]'
terraform state rm 'module.eks.module.fargate.aws_eks_fargate_profile.this["default"]'
terraform state rm 'module.eks.module.fargate.aws_iam_role_policy_attachment.eks_fargate_pod[0]'
```

### EKS Managed Node Groups

```sh
terraform state rm 'module.eks.module.node_groups.aws_eks_node_group.workers["example"]'
```

### Self Managed Node Groups

```sh
terraform state rm 'module.eks.aws_launch_template.workers_launch_template[0]'
terraform state rm 'module.eks.aws_autoscaling_group.workers_launch_template[0]'
terraform state rm 'module.eks.aws_iam_instance_profile.workers_launch_template[0]'
```

## Misc

- `module.eks.local_file.kubeconfig[0]` will be destroyed, users are encouraged to use `aws eks update-kubeconfig --name <cluster-name>` in its place
