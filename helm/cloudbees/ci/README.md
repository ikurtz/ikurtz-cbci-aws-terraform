> [!WARNING]
> **Prerequisite**: [Create a Cluster](../../)

## Install Cloudbees CI
Copy the values file _(again, the target file is ignored by git)_. Update the ACM arn, and the domain (with the A/CNAME) you intend to use to reach CI.
```bash
cp basic-values.yaml.example basic-values.yaml

## Update with ACM Arn, and domain data

kubectl create ns cloudbees-core
helm upgrade -i cloudbees-ci cloudbees/cloudbees-core -f basic-values.yaml -n cloudbees-core
```