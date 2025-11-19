
###########################
# IAM Role for CodeBuild #
###########################
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "buildphase-codebuild-eks-devops-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "buildphase-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
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

resource "aws_iam_role_policy" "codebuild_ecr" {
  name = "codebuild-ecr-access"
  role = aws_iam_role.codebuild_role.id

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

##################
# CodeBuild Project - Build Stage #
##################
resource "aws_codebuild_project" "build_eks_devops" {
  name          = "build-eks-devops"
  service_role  = aws_iam_role.codebuild_role.arn
  description   = "Build project for EKS DevOps pipeline"
  build_timeout = 60

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-build.yml"
}

  artifacts {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "buildphase-cb-eks-devops-group"
      stream_name = "buildphase-cb-eks-devops-stream"
    }
  }
}



