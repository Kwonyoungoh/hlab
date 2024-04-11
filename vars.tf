variable "aws_region" {
  type    = string
  description = "The AWS region to deploy resources into"
}

variable "vpc_cidr" {
  type    = string
  description = "CIDR block for the VPC"
}

variable "project_name" {
  type = string
  description = "project_name"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  description = "List of CIDR blocks for the private subnets"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  description = "List of CIDR blocks for the public subnets"
}

variable "iam_access_key" {
  type = string
  description = "Private key for Authentication."
}

variable "iam_secret_key" {
  type = string
  description = "Private key for Authentication."
}

variable "azs" {
  type    = list(string)
  description = "A list of availability zones in the region"
  default     = ["ap-northeast-2a", "ap-northeast-2b"]
}