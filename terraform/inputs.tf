variable "public-subnet-count" {
  type = number
  description = "The number of PUBLIC subnets to create"
  default = 2
  validation {
    condition = var.public-subnet-count > 0 && var.public-subnet-count < 10
    error_message = "There must be at least 1 public subnet"
  }
}

variable "private-subnet-count" {
  type = number
  description = "The number of PRIVATE subnets to create. This also current dictates the number of node-groups created for the cluster - 1 per private subnet."
  default = 2
  validation {
    condition = var.private-subnet-count > 0 && var.private-subnet-count < 100
    error_message = "There must be at least 1 private subnet"
  }
}

variable "resource-prefix" {
  type = string
  default = "ikurtz-cbci-aws-reinvent-2023"
}

variable "aws-config" {
  type = object({
    profile = string
    region = string
    zone = string
  })
  description = "AWS Configuration items"
  default = {
    profile = "cloudbees-sa-infra-admin"
    region = "us-east-1"
    zone = "us-east-1b"
  }
}

variable "common-tags" {
  type = object({
    cb-environment = string
    cb-expiry = string
    cb-owner = string
    cb-user = string
  })
  description = "A simple hash map of key-value pairs that will be attached to each object created by this terraform."

  validation {
    condition = contains(["development", "demo", "staging", "production"], var.common-tags.cb-environment)
    error_message = "Valid values for cb-environment: [development, demo, staging, production]."
  }
  validation {
    condition     = can(regex("(\\d\\d\\d\\d)-(\\d\\d)-(\\d\\d)", var.common-tags.cb-expiry))
    error_message = "The cb-expiry argument requires a valid timestamp in the format: YYYY-MM-DD."
  }
  validation {
    condition = can(regex("^[a-z-_]+", var.common-tags.cb-owner))
    error_message = "Lowercase letters, dashes, and underscores only."
  }
  validation {
    condition = can(regex("^[a-z]+", var.common-tags.cb-user))
    error_message = "Lowercase letters only."
  }
  default = {
    cb-environment = "development",
    cb-expiry      = "2024-12-30",
    cb-owner       = "solution-architecture",
    cb-user        = "ikurtz"
  }
}

variable "vpc-cidr-block" {
  type = string
  default = "172.0.0.0/16"
}

variable "subnet-cidr-prefix" {
  type = string
  default = "172.0"
  validation {
    condition = var.subnet-cidr-prefix != "0.0"
    error_message = "The subnet-cidr-prefix must be valid! i.e. 172.0 or 10.2 - something other than 0.0"
  }
}

variable "kubernetes-version" {
  type = string
  description = "The version of kubernetes to use for the cluster"
  default = "1.27"
  validation {
    condition = can(regex("\\d\\.\\d.*", var.kubernetes-version))
    error_message = "Please enter a valid kubernetes version"
  }
}

variable "eks-node-group-instance-types" {
  type = list
  description = "A list of valid EC2 instances types that can be created within the node group"
  default = ["m7g.xlarge"]
  validation {
    condition = length(var.eks-node-group-instance-types) > 0
    error_message = "You must specify at least 1 instance type in list format"
  }
}

variable "eks-nodes-per-nodegroup" {
  type = number
  description = "How many nodes should exist in each nodegroup created"
  default = 2
  validation {
    condition = var.eks-nodes-per-nodegroup > 0 && var.eks-nodes-per-nodegroup <= 10
    error_message = "There must be at least 1 node per nodegroup, and for safety purposes no more than 10 without changing this condition"
  }
}

variable "eks-max-nodes-per-nodegroup" {
  type = number
  description = "Maximum nodes that should exist in each nodegroup created"
  default = 6
  validation {
    condition = var.eks-max-nodes-per-nodegroup > 1 && var.eks-max-nodes-per-nodegroup <= 50
    error_message = "For safety purposes no more than 50 without changing this condition"
  }
}

locals {
  # tflint-ignore: terraform_unused_declarations
  validate_nodegroup_numbers = (var.eks-max-nodes-per-nodegroup > var.eks-nodes-per-nodegroup) ? true : tobool("eks-max-nodes-per-nodegroup must be greater than eks-nodes-per-nodegroup!")
}
