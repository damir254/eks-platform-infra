terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41"
    }


    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.1"
    }

  }

  backend "s3" {
    bucket       = "damir-eks-platform-tf-state"
    key          = "eks-platform/dev/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
