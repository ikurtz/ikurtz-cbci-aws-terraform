// Modules
module "vpc" {
  source                = "./modules/vpc"
  availability_zones    = data.aws_availability_zones.available.names
  resource-prefix       = var.resource-prefix
  public-subnet-count   = var.public-subnet-count
  private-subnet-count  = var.private-subnet-count
  cidr-block            = var.vpc-cidr-block
  subnet-cidr-prefix    = var.subnet-cidr-prefix
}

module "eks" {
  source             = "./modules/eks"
  cluster-name       = var.resource-prefix
  k8s_version        = var.kubernetes-version
  vpcid              = module.vpc.vpcid
  vpc-cidr           = var.vpc-cidr-block
  private-subnet-ids = module.vpc.private-subnet-ids
}

module "efs" {
  source             = "./modules/efs"
  private-subnet-ids = module.vpc.private-subnet-ids
  cluster-name       = var.resource-prefix
  vpcid              = module.vpc.vpcid
  vpc-cidr           = var.vpc-cidr-block
}

module "eks-nodes-ec2" {
  source                                               = "./modules/eks-nodes-ec2"
  cluster-name                                         = var.resource-prefix
  aws_iam_role_node_arn                                = module.eks.aws_iam_role_node_arn
  nodegroup-name                                       = "ng"
  policy_attachment_AmazonEC2ContainerRegistryReadOnly = module.eks.policy_attachment_AmazonEC2ContainerRegistryReadOnly
  policy_attachment_AmazonEKSWorkerNodePolicy          = module.eks.policy_attachment_AmazonEKSWorkerNodePolicy
  policy_attachment_AmazonEKS_CNI_Policy               = module.eks.policy_attachment_AmazonEKS_CNI_Policy
  policy_attachment_AmazonSSMManagedInstanceCore       = module.eks.policy_attachment_AmazonSSMManagedInstanceCore
  private-subnet-ids                                   = module.vpc.private-subnet-ids
  instance_types                                       = var.eks-node-group-instance-types
  size_max                                             = var.eks-max-nodes-per-nodegroup
  size_desired                                         = var.eks-nodes-per-nodegroup
}

resource "null_resource" "create_kubeconfig" {
  triggers = {
    always_run = timestamp() #Force to recreate on every apply
  }

  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster-name}"
  }
}