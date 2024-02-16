terraform {
  required_version = "~> 1.5.6"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
