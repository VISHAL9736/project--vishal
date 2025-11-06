output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.olake_vm.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.olake_vm.public_ip
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.olake_vm.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.olake_vpc.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.olake_sg.id
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.olake_vm.public_ip}"
}

output "olake_ui_url" {
  description = "OLake UI URL"
  value       = "http://${aws_instance.olake_vm.public_ip}:8000"
}

output "instance_state" {
  description = "Instance state"
  value       = aws_instance.olake_vm.instance_state
}

output "availability_zone" {
  description = "Availability zone"
  value       = aws_instance.olake_vm.availability_zone
}

output "ami_id" {
  description = "AMI ID used"
  value       = aws_instance.olake_vm.ami
}