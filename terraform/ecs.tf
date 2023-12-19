# ECS
resource "aws_ecs_cluster" "batch_ecs_cluster" {
  name = "batch"
}

resource "aws_ecs_task_definition" "app_ecs_task_definition" {
  family                   = "batch"
  cpu                      = "1024"
  memory                   = "3072"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
  task_role_arn            = module.ecs_task_role.iam_role_arn
  container_definitions = jsonencode([
    {
      name      = "batch"
      image     = "330361183183.dkr.ecr.ap-northeast-1.amazonaws.com/spring-batch-demo:0.0.4-SNAPSHOT"
      essential = true
      environment : [
        {
          name  = "S3_URL_PERSONDATACSV"
          value = "s3://${aws_s3_bucket.csv_data_bucket.bucket}/${aws_s3_object.csv_data_bucket_object.key}"
        },
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:mysql://${aws_db_instance.batch_db.address}/db"
        }
      ],
      secrets : [
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${aws_db_instance.batch_db.master_user_secret[0].secret_arn}:username::"
        },
        {
          name : "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${aws_db_instance.batch_db.master_user_secret[0].secret_arn}:password::"
        }
      ],
      logConfiguration : {
        logDriver : "awslogs"
        options : {
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "batch"
          awslogs-group         = "/ecs/batch"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/batch"
  retention_in_days = 180
}

