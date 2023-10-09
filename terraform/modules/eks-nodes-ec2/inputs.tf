variable "cluster-name" {}

variable "private-subnet-ids" {}

variable "policy_attachment_AmazonEKSWorkerNodePolicy" {}

variable "policy_attachment_AmazonEKS_CNI_Policy" {}

variable "policy_attachment_AmazonEC2ContainerRegistryReadOnly" {}

variable "policy_attachment_AmazonSSMManagedInstanceCore" {}

variable "aws_iam_role_node_arn" {}

variable "nodegroup-name" {}

variable "size_min" {
  default = 1
}

variable "size_max" {
  default = 1
}

variable "size_desired" {
  default = 1
}

variable "instance_types" {
  default = ["t3.xlarge", "t3.2xlarge"]
}
