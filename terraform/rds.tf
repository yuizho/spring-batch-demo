resource "aws_db_parameter_group" "batch_db_parameter_group" {
  name   = "batch-db-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

resource "aws_db_subnet_group" "batch_db_subnet_group" {
  name       = "batch-db-subnet-group"
  subnet_ids = [for i in aws_subnet.batch_subnet_private : i.id]
}

resource "aws_db_instance" "batch_db" {
  allocated_storage           = 10
  identifier                  = "batch-db"
  db_name                     = "db"
  engine                      = "mysql"
  engine_version              = "8.0.33"
  instance_class              = "db.t3.micro"
  username                    = "admin"
  manage_master_user_password = true
  vpc_security_group_ids = [
    module.batch_db_sg.security_group_id
  ]
  parameter_group_name = aws_db_parameter_group.batch_db_parameter_group.name
  db_subnet_group_name = aws_db_subnet_group.batch_db_subnet_group.name
  skip_final_snapshot  = true
}

output "batch_db_instance_url" {
  value = aws_db_instance.batch_db.address
}
