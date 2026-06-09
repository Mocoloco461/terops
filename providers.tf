terraform {

  backend "s3" {
    bucket       = "homelab-terops-state"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }


  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.95.1-rc1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.ENDPOINT
  api_token = var.API_TOKEN
  insecure  = true ## WHAT FOR?
}
