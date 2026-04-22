output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  value = module.eks.cluster_version
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "rds_port" {
  value = module.rds.db_instance_port
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "frontend_ecr_repository_url" {
  value = module.frontend_ecr.repository_url
}

output "db_secret_arn" {
  value = module.db_secret.secret_arn
}

output "github_actions_app_repo_role_arn" {
  value = module.github_oidc_app_repo.github_actions_role_arn
}
