resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}
# AWS IAM can retrieve the certificate chain for OIDC providers; GitHub docs specify
# the provider URL and audience for AWS as token.actions.githubusercontent.com and
# sts.amazonaws.com. :contentReference[oaicite:0]{index=0}

resource "aws_iam_role" "github_actions_ecr" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.role_name
  })
}
# GitHub recommends restricting the trust relationship using OIDC claims such as aud
# and sub. For a workflow that runs on pushes to main, the subject claim format above
# is the correct restriction pattern. :contentReference[oaicite:1]{index=1}

resource "aws_iam_policy" "github_actions_ecr_push" {
  name = "${var.role_name}-ecr-push"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushBackendFrontend"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = [
          var.backend_ecr_repo_arn,
          var.frontend_ecr_repo_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_push" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.github_actions_ecr_push.arn
}
