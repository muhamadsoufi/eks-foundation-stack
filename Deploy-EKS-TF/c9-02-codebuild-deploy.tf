###########################
# IAM Role for CodeBuild #
###########################
data "aws_iam_policy_document" "codebuild_deploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# 2. تعریف نقش CodeBuild
resource "aws_iam_role" "codebuild_deploy_role" {
  name               = "deployphase-codebuild-eks-devops-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_deploy_assume_role.json
}

# 3. سیاست دسترسی CodeBuild (مجوزهای عمومی و فرض نقش دوم)
resource "aws_iam_role_policy" "codebuild_deploy_policy" {
  name = "deployphase-codebuild-policy"
  role = aws_iam_role.codebuild_deploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # دسترسی به CloudWatch Logs
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      # دسترسی به CodePipeline S3 Bucket
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [aws_s3_bucket.codepipeline_bucket.arn, "${aws_s3_bucket.codepipeline_bucket.arn}/*"]
      },
      # دسترسی به CodeStar Connection
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
        Resource = [aws_codestarconnections_connection.eks-application.arn]
      },
      # دسترسی ECR
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
      # 💥 مجوز کلیدی: اجازه می‌دهد این نقش، نقش EKS Kubectl را assume کند 💥
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = aws_iam_role.eks_kubectl_role.arn # <-- نقش جدید EKS
      }
    ]
  })
}
##################
# CodeBuild Project - Deploy Stage #
##################
resource "aws_codebuild_project" "deploy_eks_devops" {
  name          = "deploy-eks-devops"
  service_role  = aws_iam_role.codebuild_deploy_role.arn
  description   = "Deploy project for EKS DevOps pipeline"
  build_timeout = 60

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
}

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "deployphase-cb-eks-devops-group"
      stream_name = "deployphase-cb-eks-devops-stream"
    }
  }
}

###########################
# IAM Role for EKS Kubectl #
###########################
data "aws_iam_policy_document" "eks_kubectl_assume_role" {
  statement {
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.codebuild_deploy_role.arn] # ارجاع به نقش CodeBuild
    }
    actions = ["sts:AssumeRole"]
  }
}

# 2. تعریف نقش EKS Kubectl (جدید)
resource "aws_iam_role" "eks_kubectl_role" {
  name               = "EKS-Kubectl-Deployment-Role"
  assume_role_policy = data.aws_iam_policy_document.eks_kubectl_assume_role.json
}

# 3. اتصال سیاست دسترسی EKS (مجوزهای مورد نیاز برای مدیریت کلاستر)
resource "aws_iam_role_policy" "eks_kubectl_describe_policy" {
  name = "eks-kubectl-describe-policy"
  role = aws_iam_role.eks_kubectl_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster"
        ]
        # محدود کردن دسترسی فقط به همین کلاستر خاص
        Resource = aws_eks_cluster.eks_cluster.arn
      }
    ]
  })
}

###########################
# EKS Access Entry: مجوز دادن به نقش جدید برای دسترسی به کلاستر
###########################
resource "aws_eks_access_entry" "eks_kubectl_access_entry" { # نام منبع تغییر کرد
  cluster_name    = aws_eks_cluster.eks_cluster.name
  principal_arn   = aws_iam_role.eks_kubectl_role.arn # 💥 استفاده از نقش جدید EKS 💥
  type            = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_kubectl_access_policy_association" { # نام منبع تغییر کرد
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_kubectl_role.arn # 💥 استفاده از نقش جدید EKS 💥

  access_scope {
    type        = "cluster"
  }
}