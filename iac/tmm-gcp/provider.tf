terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"  # You can adjust this version as needed
    }
  }
}

provider "google" {
  project = "tmm-fcs-444213"
}

provider "random" {}
