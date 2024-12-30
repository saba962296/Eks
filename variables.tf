# modules/eks/variables.tf

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for encryption"
  type        = string
}

variable "internal_cidr_blocks" {
  description = "CIDR blocks for internal network"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"  # Example default
}
