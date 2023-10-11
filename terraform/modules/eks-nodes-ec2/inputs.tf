variable "cluster-name" {}

variable "private-subnet-ids" {}

variable "policy_attachment_AmazonEKSWorkerNodePolicy" {}

variable "policy_attachment_AmazonEKS_CNI_Policy" {}

variable "policy_attachment_AmazonEC2ContainerRegistryReadOnly" {}

variable "policy_attachment_AmazonSSMManagedInstanceCore" {}

variable "aws_iam_role_node_arn" {}

variable "nodegroup-name" {}

variable "ami-type" {
  default = "AL2_ARM_64"
}

variable "size_min" {
  default = 1
}

variable "size_max" {
  default = 6
}

variable "size_desired" {
  default = 2
}

variable "instance_types" {
  default = ["m7g.xlarge", "m7g.xlarge"]
}
