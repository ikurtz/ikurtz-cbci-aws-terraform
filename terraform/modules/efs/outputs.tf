output "efs-mount-target" {
  value = aws_efs_file_system.main.dns_name
}

output "efs-file-system-id" {
  value = aws_efs_file_system.main.id
}


