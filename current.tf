provider "aws" {
  region = var.aws_region
  version = ">= 3.0"
  default_tags {
        tags = {"danske:account-name":"kklp-loyaltykey-test"}
    }

  ignore_tags {
    key_prefixes = [
      "danske:dynamic:",
      "danske:image-approved",
      "danske:image-compliant",
      "danske:ami:build-release",
      "danske:ami:name",
      "danske:environment",
      "danske:spi",
    ]
  }
}
module "iam_policy" {
  source  = "artifactory.danskenet.net/joined-terraform__terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "example"
  path        = "/"
  description = "My example policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
module "s3_bucket" {
  source = "artifactory.danskenet.net/joined-terraform__terraform-aws-modules/s3-bucket/aws"
  version = "4.2.2"
  bucket = "my-s3-bucket-kklp-27122024"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}


resource "aws_s3_bucket_policy" "alb_write_policy"{
  bucket = "my-s3-bucket-kklp-27122024" #module.s3_bucket.bucket_name
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::054676820928:root"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::my-s3-bucket-kklp-27122024/AWSLogs/940482453147/*"
        }
    ]
}
 EOF
}


module "log_group" {
  source  = "artifactory.danskenet.net/joined-terraform__terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 3.0"

  name              = "kklp-test-group"
  retention_in_days = 120
}

module "kms" {
  source  = "artifactory.danskenet.net/joined-terraform__terraform-aws-modules/kms/aws"
  
 
    description = "KMS key for EKS cluster"
    deletion_window_in_days = 7
    enable_key_rotation = true
      policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Default",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::940482453147:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of key for infrastructure roles within organisation",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:Encrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey",
                "kms:CreateGrant",
                "kms:Decrypt"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": "o-ck0sjjnnc2"
                },
                "StringLike": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::*:role/infra/SecurityManager",
                        "arn:aws:iam::*:role/infra/CloudManager",
                        "arn:aws:iam::*:role/infra/Configurator"
                    ]
                }
            }
        }
    ]
}
EOF

    aliases = ["kklp-eks-kms"]
    tags = {
    environment = "test"
  }
    
  
}
module "kms_additional" {
  source  = "artifactory.danskenet.net/joined-terraform__terraform-aws-modules/kms/aws"
  
 
    description = "KMS key for rds"
    deletion_window_in_days = 7
    enable_key_rotation = true
      policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Default",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::940482453147:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of key for infrastructure roles within organisation",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:Encrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey",
                "kms:CreateGrant",
                "kms:Decrypt"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": "o-ck0sjjnnc2"
                },
                "StringLike": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::*:role/infra/SecurityManager",
                        "arn:aws:iam::*:role/infra/CloudManager",
                        "arn:aws:iam::*:role/infra/Configurator"
                    ]
                }
            }
        }
    ]
}
EOF

    aliases = ["kklp-aurora-kms"]
    tags = {
    environment = "test"
  }
    
  
}
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "EKS Cluster Role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "EKS Node Role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_role_attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  role       = aws_iam_role.eks_node_role.name
  policy_arn = each.value
}

resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster-sg"
  vpc_id = "vpc-0d4befaae1efca56d"
  ingress {
    description = "Allow EKS traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "EKS Security Group"
  }
}
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "kklp-test-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids              = ["subnet-017ec8abb67ae7869", "subnet-009a7f04ba71d0ea1"]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }
  enabled_cluster_log_types = ["api", "audit", "controllerManager", "scheduler", "authenticator"]
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = "arn:aws:kms:eu-central-1:940482453147:key/790e9691-91d5-4f91-a768-31fa4682cf9e"
    }
  }
  version = "1.27"
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "aws_eks_node_group" "m_n_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "basic-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = ["subnet-017ec8abb67ae7869", "subnet-009a7f04ba71d0ea1"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  instance_types = ["t3.medium"]
  tags = {
    Name = "Basic Node Group"
  }
  version = "1.27" 
}

/*
resource "aws_eks_cluster" "eks_cluster" {
  name     = "kklp-test-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids              = ["subnet-017ec8abb67ae7869", "subnet-009a7f04ba71d0ea1"]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }
  enabled_cluster_log_types = ["api", "audit", "controllerManager", "scheduler", "authenticator"]
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = "arn:aws:kms:eu-central-1:940482453147:key/790e9691-91d5-4f91-a768-31fa4682cf9e"
    }
  }
  version = "1.27"
}

resource "aws_eks_node_group" "m_n_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "basic-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = ["subnet-017ec8abb67ae7869", "subnet-009a7f04ba71d0ea1"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  instance_types = ["t3.medium"]
  tags = {
    Name = "Basic Node Group"
  }
  version = "1.27" 
}
*/

resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "EKS Fargate Pod Execution Role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_attachment" {
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "kklp" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "kklp-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = ["subnet-017ec8abb67ae7869", "subnet-009a7f04ba71d0ea1"]

  selector {
    namespace = "default"
  }

  tags = {
    Name = "EKS Fargate Profile"
  }
}
resource "aws_security_group" "aurora_sg" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow postgressql traffic"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["sg-0050453df6697f3cc"]
  }
  egress {
    description = "Allow all outboubd traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Aurora Security Group"
  }
}
resource "aws_db_subnet_group" "aurora_subnet_group" {
    name = "aurora-subnet-group"
    subnet_ids= ["subnet-017ec8abb67ae7869","subnet-009a7f04ba71d0ea1"]
    tags ={
        Name  ="Aurora Subnet Group"
    }
  
}

resource "aws_rds_cluster_parameter_group" "aurora_tls_15" {
name = "aurora-tls-parameter-group-15"
family = "aurora-postgresql15"

parameter {
  name="rds.force_ssl"
  value=1
}


tags={
    Name="Aurora TLS Parameter Group"
}

}

resource "aws_rds_cluster" "aurora_serverless" {

    cluster_identifier = "kklp-aurora-cluster"
    engine = "aurora-postgresql"
    engine_version = "15.4"
   
    master_username = "postgres"
    master_password = "admin12345!"
    database_name = "loyaltyrewards01"
    db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
    vpc_security_group_ids = [aws_security_group.aurora_sg.id]
    storage_encrypted = true
    kms_key_id = "arn:aws:kms:eu-central-1:940482453147:key/25406a1a-3baf-4929-aa7a-aed9a8a39e4b"
    backup_retention_period = 7
    preferred_backup_window = "03:00-06:00"
    preferred_maintenance_window = "Sun:06:00-Sun:07:00"
    iam_database_authentication_enabled = true
    copy_tags_to_snapshot = true
    db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_tls_15.name
    skip_final_snapshot = true

    enabled_cloudwatch_logs_exports = ["postgresql"]

    serverlessv2_scaling_configuration {
      min_capacity = 2
      max_capacity = 8
    }

    tags = {
      Name="Aurora Serveless cluster"
    }
  
}

resource "aws_rds_cluster_instance" "aurora_serverless_v2_instance" {
  count              = 1
  identifier         = "aurora-serverless-v2-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_serverless.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_serverless.engine
  engine_version     = aws_rds_cluster.aurora_serverless.engine_version
}




resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow alb traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["sg-0050453df6697f3cc"]
  }
  egress {
    description = "Allow all outboubd traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ALB Security Group"
  }
}

resource "aws_lb" "private_application_lb" {
  name="eks-kklp-lb"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = ["subnet-017ec8abb67ae7869","subnet-009a7f04ba71d0ea1"]
  access_logs {
    bucket = "my-s3-bucket-kklp-27122024"
    enabled = true
  }

  tags = {
    Name="EKS Private ALB"
  }
}
/*
resource "aws_lb_target_group" "eks_target_group" {

    name="eks-priv"
    port = 443
    protocol = "HTTPS"
    vpc_id = "vpc-0d4befaae1efca56d"

    health_check {
      path = "/health"
      protocol = "HTTP"
      interval = 30
      timeout = 5
      healthy_threshold = 3
      unhealthy_threshold = 3
    }
    

    tags = {
      Name="EKS Priv TG"
    }
    connection_termination = false
  
}

resource "aws_lb_listener" "http_lis" {
  load_balancer_arn = aws_lb.private_application_lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:eu-central-1:940482453147:certificate/f2e6f93a-5ea8-46ef-b64e-4e3bad542333"
  default_action {
    type="forward"
    target_group_arn = aws_lb_target_group.eks_target_group.arn
  }
}
*/
resource "aws_lb_listener" "http_lis" {
  load_balancer_arn = aws_lb.private_application_lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  #certificate_arn = "arn:aws:acm:eu-central-1:940482453147:certificate/f2e6f93a-5ea8-46ef-b64e-4e3bad542333"
  certificate_arn = "arn:aws:acm:eu-central-1:940482453147:certificate/6faceb10-9090-4969-a21a-d18e717c3c71"
  default_action {
    type="fixed-response"
    fixed_response {
      
        status_code=200
        content_type ="text/plain"
        message_body="ALB is running on https"
      
    }
  }
}


#eof
