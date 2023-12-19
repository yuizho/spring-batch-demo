resource "aws_sfn_state_machine" "batch-ecs-start" {
  name     = "batch-ecs-start"
  role_arn = module.stepfunctions_ecs_task_execution_role.iam_role_arn


  definition = jsonencode({
    Comment = "batch 実行用のステートマシン"
    StartAt = "ECS RunTask"
    States = {
      "ECS RunTask" = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.batch_ecs_cluster.arn
          TaskDefinition = aws_ecs_task_definition.app_ecs_task_definition.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              SecurityGroups = [
                module.able_to_access_rds_sg.security_group_id
              ],
              Subnets = [
                aws_subnet.batch_subnet_private[var.private_subnets[0].az].id
              ]
            }
          }
        },
        End = true
      }
    }
  })
}
