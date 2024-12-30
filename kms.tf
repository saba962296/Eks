# modules/kms/kms.tf
resource "aws_kms_key" "eks_key" {
  description = "KMS key for EKS secrets encryption"
  key_usage   = "ENCRYPT_DECRYPT"
  policy      = data.aws_iam_policy_document.kms_key_policy.json
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    actions   = ["kms:Encrypt", "kms:Decrypt"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

output "kms_key_arn" {
  value = aws_kms_key.eks_key.arn
}
