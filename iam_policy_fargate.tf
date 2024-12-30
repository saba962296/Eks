# modules/iam/iam_policy_fargate.tf
resource "aws_iam_policy" "eks_fargate_policy" {
  name        = "eks-fargate-policy"
  description = "Fargate Role Policy"

  policy = data.aws_iam_policy_document.eks_fargate_policy_document.json
}

data "aws_iam_policy_document" "eks_fargate_policy_document" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeFargateProfile",
      "eks:CreateFargateProfile",
      "eks:DeleteFargateProfile"
    ]
    resources = ["arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/*"]
  }
}
