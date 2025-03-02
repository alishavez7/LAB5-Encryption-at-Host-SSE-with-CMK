terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {

  }
  subscription_id = "b2b1a439-1ecd-424a-8646-fe44b9e39ff8"
}
