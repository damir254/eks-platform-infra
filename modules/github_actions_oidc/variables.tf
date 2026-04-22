variable "role_name" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "backend_ecr_repo_arn" {
  type = string
}

variable "frontend_ecr_repo_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
