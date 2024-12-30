# modules/eks/security_group.tf
resource "aws_security_group" "eks_security_group" {
  name        = "eks-cluster-sg"
  description = "EKS Security Group - Only allow internal access"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from internal network only (private CIDR block)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_cidr_blocks
  }

  # Allow outbound traffic to all destinations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
