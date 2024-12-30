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
  default     = "us-west-2"  # Example default region
}
=======================================================================================
# terraform.tfvars

cluster_name          = "my-cluster"
vpc_id                = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your actual VPC ID
subnet_ids            = ["subnet-xxxxxxxx", "subnet-yyyyyyyy", "subnet-zzzzzzzz"]  # Replace with your actual subnet IDs
kms_key_arn           = "arn:aws:kms:us-west-2:123456789012:key/xxxxxxxxxxxxxxxxxxxx"  # Replace with your actual KMS Key ARN
internal_cidr_blocks  = ["10.0.0.0/27", "10.0.0.32/27", "10.0.0.64/27"]  # Replace with your actual internal CIDR blocks
region                = "us-west-2"  # Replace with your AWS region

====================================================================================
module "eks_cluster" {
  source                = "./modules/eks/eks_cluster"
  cluster_name          = var.cluster_name
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_ids
  kms_key_arn           = var.kms_key_arn
  internal_cidr_blocks  = var.internal_cidr_blocks
  region                = var.region
}
