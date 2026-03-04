variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "ci-demo-eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ecr_account_id" {
  description = "AWS Account ID for ECR"
  type        = string
  default     = "942165495572"
}

variable "ecr_repository" {
  description = "ECR repository name"
  type        = string
  default     = "python/demo"
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "MukeshSingh14/CI-Demo"
}
