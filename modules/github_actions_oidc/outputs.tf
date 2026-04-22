output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
