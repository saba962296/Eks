# modules/iam/iam_policy_eks.tf
resource "aws_iam_policy" "eks_policy" {
  name        = "eks-cluster-policy"
  description = "EKS Cluster Policy"

  policy = data.aws_iam_policy_document.eks_policy_document.json
}

data "aws_iam_policy_document" "eks_policy_document" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:UpdateClusterVersion",
      "eks:CreateCluster",
      "eks:DeleteCluster",
      "eks:ListClusters"
    ]
    resources = ["arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeInstances",
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}
