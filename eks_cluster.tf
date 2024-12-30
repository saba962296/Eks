resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.27"  # Kubernetes version

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_security_group.id]
    public_access      = false  # Private access only
    private_access     = true   # Enable private access to the EKS API
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  addon {
    addon_name    = "coredns"
    addon_version = "v1.10.1"
  }

  addon {
    addon_name    = "kube-proxy"
    addon_version = "v1.27.1"
  }

  addon {
    addon_name    = "vpc-cni"
    addon_version = "v1.12.6"
  }

  addon {
    addon_name    = "aws-ebs-csi-driver"
    addon_version = "v1.20.0"
  }
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_kubeconfig" {
  value = aws_eks_cluster.eks_cluster.kubeconfig
}
