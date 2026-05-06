terraform {
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
}
