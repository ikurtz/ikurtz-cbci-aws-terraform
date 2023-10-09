resource "aws_efs_file_system" "main" {
  creation_token   = var.cluster-name
  performance_mode = "generalPurpose"
  tags             = {
    Name = var.cluster-name
  }
}

resource "aws_security_group" "efs_sg" {
  name = "${var.cluster-name}_efs_sg"
  description = "Cluster communication with worker nodes"
  vpc_id = var.vpcid

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc-cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}_eks_sg"
  }
}

resource "aws_efs_mount_target" "main_mounts" {
  count           = length(var.private-subnet-ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private-subnet-ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}
