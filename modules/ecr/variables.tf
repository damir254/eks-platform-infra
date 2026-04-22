variable "name" {
  type = string
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "tags" {
  type    = map(string)
  default = {}
}
