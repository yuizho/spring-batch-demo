provider "aws" {
  region = "ap-northeast-1"
}

# to get aws account id
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}
