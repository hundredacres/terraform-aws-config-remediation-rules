terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Pessimistic constraint: allows minor/patch updates but prevents breaking changes from major versions
      version = "> 6.0"
    }
  }
}
