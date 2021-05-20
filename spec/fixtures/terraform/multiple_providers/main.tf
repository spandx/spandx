terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
    azure = {
      source = "hashicorp/azurerm"
      version = "~> 2.1"
    }
  }
}
