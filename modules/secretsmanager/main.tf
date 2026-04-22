resource "aws_secretsmanager_secret" "this" {
  name = var.name

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}
