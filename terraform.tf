terraform {
  required_version = ">= 1.12"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}