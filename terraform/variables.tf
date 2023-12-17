# network
variable "public_subnets" {
  type = list(object({
    az   = string
    cidr = string
  }))
  default = [
    {
      az   = "ap-northeast-1a",
      cidr = "10.0.10.0/24"
    },
    {
      az   = "ap-northeast-1c",
      cidr = "10.0.11.0/24"
    }
  ]
}

variable "private_subnets" {
  type = list(object({
    az   = string
    cidr = string
  }))
  default = [
    {
      az   = "ap-northeast-1a",
      cidr = "10.0.20.0/24"
    },
    {
      az   = "ap-northeast-1c",
      cidr = "10.0.21.0/24"
    }
  ]
}
