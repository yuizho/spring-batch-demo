# EC2
resource "aws_instance" "rds_bastion_ec2" {
  ami                  = "ami-03203d8898a3a412b"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  vpc_security_group_ids = [
    module.able_to_access_rds_sg.security_group_id
  ]
  subnet_id = aws_subnet.batch_subnet_private[var.private_subnets[0].az].id

  user_data = <<-EOF
    #!/bin/bash
  EOF

  tags = {
    Name = "rds_bastion"
  }
}

# Session Manager
resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}

# log config of Session Manager
resource "aws_cloudwatch_log_group" "ec2_ssm_operation" {
  name              = "/ec2-ssm-operation"
  retention_in_days = 180
}

# output
output "operation_instance_id" {
  value = aws_instance.rds_bastion_ec2.id
}
