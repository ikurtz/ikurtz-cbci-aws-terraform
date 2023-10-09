
output "efsMountTarget" {
  value = module.efs.efs-mount-target
}
output "efsSystemId" {
  value = module.efs.efs-file-system-id
}
output "resourcePrefix" {
  value = var.resource-prefix
}
output "eksNodeRoleArn" {
  value = module.eks.aws_iam_role_node_arn
}
output "eksClusterName" {
  value = module.eks.cluster-name
}
output "eksClusterId" {
  value = module.eks.cluster_id
}
output "eksClusterStatus" {
  value = module.eks.status
}
output "eksClusterEndpoint" {
  value = module.eks.eks_ep
}
