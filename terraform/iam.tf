locals {
  account_id = data.aws_caller_identity.current.account_id
}

# source policy documents
data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# docker pullに必要
data "aws_iam_policy" "container_registry_readonly_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "s3_read_only_acess" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# policy documents
data "aws_iam_policy_document" "vpc_endpoint_for_s3" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:GetObject"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "ec2_for_ssm" {
  source_policy_documents = [data.aws_iam_policy.ec2_for_ssm.policy]

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "ssm:GetParametersByPath",
      "kms:Decrypt",
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_policy_documents = [
    data.aws_iam_policy.ecs_task_execution_role_policy.policy,
    data.aws_iam_policy.container_registry_readonly_policy.policy,
  ]

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "kms:Decrypt",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_task" {
  source_policy_documents = [
    data.aws_iam_policy.s3_read_only_acess.policy
  ]
}


data "aws_iam_policy_document" "stepfunctions_ecs_task_execution" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = [aws_ecs_task_definition.app_ecs_task_definition.arn]
  }

  statement {
    sid    = "VisualEditor0"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/*"]
  }
}


# iam role
module "ec2_for_ssm_role" {
  source = "./modules/iam_role"
  name   = "ec2-for-ssm"
  // 信頼ポリシーに「ec2.amazonaws.com」を指定し、このIAMロールをEC2インスタンスで使うことを宣言する
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

module "ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "app-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "ecs_task_role" {
  source     = "./modules/iam_role"
  name       = "app-ecs-task"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task.json
}

module "stepfunctions_ecs_task_execution_role" {
  source     = "./modules/iam_role"
  name       = "stepfunctions-ecs-task-execution"
  identifier = "states.amazonaws.com"
  policy     = data.aws_iam_policy_document.stepfunctions_ecs_task_execution.json
}
