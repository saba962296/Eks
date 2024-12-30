resource "aws_iam_role" "eks_fargate_role" {
  name               = "eks-fargate-role"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role_policy.json

  tags = {
    Name = "eks-fargate-role"
  }
}

data "aws_iam_policy_document" "eks_fargate_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate.amazonaws.com"]
    }
  }
}
