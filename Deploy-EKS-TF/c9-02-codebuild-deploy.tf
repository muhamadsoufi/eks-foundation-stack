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

resource "aws_iam_role" "codebuild_deploy_role" {
  name               = "deployphase-codebuild-eks-devops-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_deploy_assume_role.json
}

resource "aws_iam_role_policy" "codebuild_deploy_policy" {
  name = "deployphase-codebuild-policy"
  role = aws_iam_role.codebuild_deploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:GetConnection","codestar-connections:GetConnectionToken"]
        Resource = [aws_codestarconnections_connection.eks-application.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_deploy_ecr" {
  name = "deployphase-codebuild-ecr-access"
  role = aws_iam_role.codebuild_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_deploy_eks_access" {
  name = "deployphase-codebuild-eks-access"
  role = aws_iam_role.codebuild_deploy_role.id

  policy = jsonencode({
  Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster", "eks:AccessKubernetesApi"]
        Resource = aws_eks_cluster.eks_cluster.arn 
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
resource "aws_eks_access_entry" "codebuild_deploy_access_entry" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = aws_iam_role.codebuild_deploy_role.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "codebuild_deploy_access_policy_association" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.codebuild_deploy_role.arn

  access_scope {
    type       = "cluster"
  }
}
