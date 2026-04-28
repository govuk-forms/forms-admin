terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }

  backend "s3" {
    bucket = "gds-forms-integration-tfstate"
    region = "eu-west-2"
    # key is set when initializing Terraform
    # e.g. `terraform init -backend-config="key=review-apps/forms-admin/pr-123.tfstate"`
  }
}

provider "aws" {
  allowed_account_ids = ["842676007477"]
  region              = "eu-west-2"

  default_tags {
    tags = {
      Environment = "review"
      Deployment  = "github.com/govuk-forms/forms-admin/.review_apps"
      PullRequest = "https://github.com/govuk-forms/forms-admin/pull/${var.pull_request_number}"
    }
  }
}
