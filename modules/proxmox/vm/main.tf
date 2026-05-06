terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.95.1-rc1"
    }
  }
}

locals {
  os_templates = {
    "ubuntu" = 80801
    "k3s"    = 80901
    "debian" = 81001
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.target_node
  started   = var.started
  on_boot = var.on_boot

  count     = var.vm_replica
  tags      = var.tags
  vm_id     = var.vm_id


  clone {
    vm_id        = lookup(local.os_templates, var.template_name, 80801)
    datastore_id = "local-zfs"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = var.storage
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = var.memory
  }

  cpu {
    cores = var.cores
  }

  initialization {
    datastore_id = "local-zfs"


    dns {
      servers = ["192.168.1.230","1.1.1.1","8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = var.ip #"192.168.1.10/24"
        # gateway = "192.168.1.1"
      }
  
    }



  }

}
