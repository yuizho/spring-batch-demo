# source policy documents
data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

# iam role
module "ec2_for_ssm_role" {
  source = "./modules/iam_role"
  name   = "ec2-for-ssm"
  // 信頼ポリシーに「ec2.amazonaws.com」を指定し、このIAMロールをEC2インスタンスで使うことを宣言する
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}
