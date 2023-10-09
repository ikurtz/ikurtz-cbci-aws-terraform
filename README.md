# AWS VPC Foundation and Clean EKS Cluster

> [!WARNING]
> **Prerequisite**: Setup [ps-common-tooling](https://github.com/cloudbees/ps-common-tooling/wiki)

> [!IMPORTANT]
> This README will walk through the steps necessary to create an EKS Cluster in AWS that is _NOT_ opinionated in anyway towards CI or CD. This is, however; opinionated in regards to how to create an EKS cluster, with what tools, and what permissions in order for things to work. There's a number of ways this is documented on the internet - we've tried to distill all that information into a handful of scripts that take a couple arguments and take you 1 step closer with each script. The point of this is NOT to be push-button. We do eventually get to installing CI in here, but it's not necessary.

## AWS Foundational EKS Cluster
### Terraform
[See our Terraform README](terraform/). This is managed by a small handful of terraform modules that use the basic "aws terraform" modules to complete their work. This should be relatively easy to follow.

### OIDC Provider
At this point in time I'm not 100% sure of the best way to manage these. This will look for an OIDC provider for the given cluster. If one is found, ok - all done. If not, you'll be given the option to create one.
```bash
# ps-common-tooling
aws-eks-oidc-check.sh <cluster-name>
```
> The counterpart to this tool is the following:
```bash
# ps-common-tooling
aws-identify-unused-oidc-providers.py
```

## Install efs driver
### Get the cluster's role
```bash
aws eks describe-cluster --name my-cluster | jq '.cluster.roleArn' -r | cut -d/ -f2
```
```bash
# ps-common-tooling
aws-eks-install-efs-driver.sh -c my-cluster -r my-cluster_role -a 1234567890
```

## Create the EFS Storage Class
This is in preparation for installing CI. At this point in time, it's just a resource in k8s waiting to be used. Copy the example file _specifically_ to `efs-storage-class.yaml` _(simply because that's what ignored in git)_, update the `fileSystemId` with the EFS created via the terraform (ID will be in the output). And... create the storage class.
```bash
cp kubectl/storage/efs-storage-class.yaml.example kubectl/storage/efs-storage-class.yaml

## Update with the efs ID from terraform output
kubectl apply -f kubectl/storage/efs-storage-class.yaml
```

## Install Loadbalancer Controller
This will be required in order for Kubernetes _ingress_ and _service_ types to integrate and authenticate with AWS in order to fullfil load-balancer type requests.
```bash
# ps-common-tooling
aws-eks-install-lb-controller.sh -c my-cluster -a 1234567890 -C
```

### Verify the controller is up
```bash
kubectl get po -n kube-system | grep ^aws
```

## To install CI...
[Check the docs here](helm/cloudbees/ci)
