variable "name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_role_name" {
  type = string
}

variable "node_role_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
