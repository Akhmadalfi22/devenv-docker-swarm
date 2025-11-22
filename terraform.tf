terraform {
  required_version = ">= 1.14" // https://github.com/hashicorp/terraform/releases
  required_providers {
    external = {
      source  = "hashicorp/external" // https://registry.terraform.io/providers/hashicorp/external/latest
      version = "~> 2.3"
    }
    random = {
      source  = "hashicorp/random" // https://registry.terraform.io/providers/hashicorp/random/latest
      version = "~> 3.7.2"
    }
    aws = {
      source  = "hashicorp/aws" // https://registry.terraform.io/providers/hashicorp/aws/latest
      version = "6.22.1"
    }
  }
}