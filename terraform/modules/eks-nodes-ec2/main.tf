## sleep for a moment, otherwise terraform doesn't recognize the cluster yet
## and the node group creation fails.
resource "null_resource" "previous" {}
resource "time_sleep" "wait_seconds" {
  depends_on = [null_resource.previous]
  create_duration = "5s"
}

resource "aws_eks_node_group" "node" {
  count           = length(var.private-subnet-ids)
  cluster_name    = var.cluster-name
  node_group_name = "${var.cluster-name}-${var.nodegroup-name}-${count.index}"
  node_role_arn   = var.aws_iam_role_node_arn
  subnet_ids      = [var.private-subnet-ids[count.index]]
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.size_desired
    max_size = var.size_max
    min_size = var.size_min
  }

  tags = {
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/${var.cluster-name}" = "owned"
    "k8s.io/cluster/${var.cluster-name}" = "owned"
  }

  depends_on = [
    time_sleep.wait_seconds,
    var.policy_attachment_AmazonEC2ContainerRegistryReadOnly,
    var.policy_attachment_AmazonEKS_CNI_Policy,
    var.policy_attachment_AmazonEKSWorkerNodePolicy,
    var.policy_attachment_AmazonSSMManagedInstanceCore
  ]

}

