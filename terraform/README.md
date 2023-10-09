# Foundational Infrastructure

> [!NOTE]
> Because this is meant to be boilerplate and user-friendly, this doesn't provide an option to re-use an existing vpc and subnets etc. Unfortunately, that takes us down somewhat of a rabbit-hole. So for simplicity's sake, this will always start fresh. 

## Managing Multiple Terraform Environments
This normally comes up as soon as you are done launching your first deployment, and you need to light up another just like it without destroying the current. The short answer here is [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces#using-workspaces). Another is Terragrunt, and I'm sure there are others. Terraform's workspaces is pretty simple and straight-forward, and likely much, much less overhead.

## A VPC, and an EKS Cluster
Once you've cloned the repo, copy the `tfvars/sample.tfvars` to `./myusername.auto.tfvars` in the terraform directory. *.auto.tfvars is ignored by git.
```
cd terraform
cp tfvars/sample.tfvars ./${USER}.auto.tfvars
```
Change your variables accordingly, and proceed as normal:
```
terraform init
terraform plan
terraform apply --auto-approve
```

At this time, this will create...
 * 1 VPC
 * Subnets according to your specification _(keep in mind that 2 public subnets are required to wire up an Application Loadbalancer)_
 * Standard networking fabric with route tables, NAT Gateway for private subnets and Internet GW for public subnets
 * 1 AWS EFS 
 * 1 EKS Cluster
 * 1 NodeGroup per (private) subnet
 * The necessary security groups to wire that together
 * A handful of IAM permissions to allow for cluster functionality

> [!WARNING]
> Unfortunately at this time the nodes within the autoscaling groups are not adding themselves to the cluster. This will be resolved as soon as someone has a chance to look into it!

> [!NOTE]
> That's it. There's no Load balancer yet as there's nothing to load balance. There's no add-ons or drivers. This is as boiler-plate as possible.