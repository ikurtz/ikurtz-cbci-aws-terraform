output "aws_iam_role_node_id" {
  value = aws_iam_role.eks_nodes.id
}

output "aws_iam_role_node_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "eks_ep" {
  value = aws_eks_cluster.main.endpoint
}

output "eks-node-role" {
  value = aws_iam_role.eks_nodes
}

output "policy_attachment_AmazonEKSWorkerNodePolicy" {
  value = aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy
}

output "policy_attachment_AmazonEKS_CNI_Policy" {
  value = aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
}

output "policy_attachment_AmazonEC2ContainerRegistryReadOnly" {
  value = aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
}

output "policy_attachment_AmazonSSMManagedInstanceCore" {
  value = aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore
}

output "status" {
  value = aws_eks_cluster.main.status
}

output "cluster_id" {
  value = aws_eks_cluster.main.id
}

output "cluster-name" {
  value = aws_eks_cluster.main.name
}

output "eks-security-group" {
  value = aws_security_group.eks_sg.id
}
