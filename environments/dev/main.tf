resource "random_password" "db" {
  length  = 20
  special = true

  lifecycle {
    prevent_destroy = false
  }
}


module "vpc" {
  source = "../../modules/vpc"

  name = "${var.project_name}-${var.environment}"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["eu-central-1a", "eu-central-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "eks" {
  source = "../../modules/eks"

  name               = "${var.project_name}-${var.environment}"
  kubernetes_version = "1.35"
  subnet_ids         = module.vpc.private_subnet_ids
  cluster_role_name  = "${var.project_name}-${var.environment}-eks-cluster-role"
  node_role_name     = "${var.project_name}-${var.environment}-eks-node-role"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "rds" {
  source = "../../modules/rds"

  name               = "${var.project_name}-${var.environment}"
  db_name            = "appdb"
  username           = "appuser"
  password           = random_password.db.result
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id

  # temporary, broad rule for early setup
  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "ecr" {
  source = "../../modules/ecr"

  name = "${var.project_name}-${var.environment}-backend"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "frontend_ecr" {
  source = "../../modules/ecr"

  name = "${var.project_name}-${var.environment}-frontend"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "db_secret" {
  source = "../../modules/secretsmanager"

  name = "${var.project_name}/${var.environment}/backend/db-damir"

  secret_string = jsonencode({
    DB_PASSWORD = random_password.db.result
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "eso_secrets_access" {
  name = "${var.project_name}-${var.environment}-eso-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = module.db_secret.secret_arn
      }
    ]
  })
}

resource "aws_iam_role" "eso_pod_identity_role" {
  name = "${var.project_name}-${var.environment}-eso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_secrets_access" {
  role       = aws_iam_role.eso_pod_identity_role.name
  policy_arn = aws_iam_policy.eso_secrets_access.arn
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso_pod_identity_role.arn
}

module "github_oidc_app_repo" {
  source = "../../modules/github_actions_oidc"

  role_name = "${var.project_name}-${var.environment}-gha-ecr"

  github_org  = "damir254"
  github_repo = "eks-microservices-app"

  backend_ecr_repo_arn  = module.ecr.repository_arn
  frontend_ecr_repo_arn = module.frontend_ecr.repository_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "argocd_image_updater_ecr_read" {
  name = "${var.project_name}-${var.environment}-argocd-image-updater-ecr-read"

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
        Sid    = "ECRRead"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = [
          module.ecr.repository_arn,
          module.frontend_ecr.repository_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "argocd_image_updater" {
  name = "${var.project_name}-${var.environment}-argocd-image-updater-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater_ecr_read" {
  role       = aws_iam_role.argocd_image_updater.name
  policy_arn = aws_iam_policy.argocd_image_updater_ecr_read.arn
}

resource "aws_eks_pod_identity_association" "argocd_image_updater" {
  cluster_name    = module.eks.cluster_name
  namespace       = "argocd"
  service_account = "argocd-image-updater-controller"
  role_arn        = aws_iam_role.argocd_image_updater.arn
}
