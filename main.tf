module "vm_proxmox_infrastructure" {
  source = "./infra/vm"
}

module "sandbox_vpc" {
  source  = "./infra/sanbox"
  RSA_PUB = var.RSA_PUB
}
