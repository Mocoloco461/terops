terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.95.1-rc1"
    }
  }
}

variable "RSA_PUB" {
  description = "SSH public key for user login"
  type        = string
  sensitive   = true
}

# ==============================================================================
# 1. SDN NETWORK ARCHITECTURE (AWS VPC SIMULATION)
# ==============================================================================

# Simple Zone: Represents the logical boundary of our Virtual Private Cloud (VPC)
resource "proxmox_virtual_environment_sdn_zone_simple" "vpc" {
  id    = "vpcprod"
  nodes = ["r620"] # Target node in the Proxmox cluster
  mtu   = 1500
}

# Public VNet: Represents the Public Subnet (e.g., connected to Internet Gateway)
resource "proxmox_virtual_environment_sdn_vnet" "public" {
  id    = "pubvnet"
  zone  = proxmox_virtual_environment_sdn_zone_simple.vpc.id
  alias = "Public Subnet (AWS VPC style)"
}

# Private VNet: Represents the Private Subnet (isolated backend)
resource "proxmox_virtual_environment_sdn_vnet" "private" {
  id    = "privnet"
  zone  = proxmox_virtual_environment_sdn_zone_simple.vpc.id
  alias = "Private Subnet (AWS VPC style)"
}

# Public Subnet IP configuration: SNAT is enabled to allow internet routing
resource "proxmox_virtual_environment_sdn_subnet" "public_subnet" {
  cidr    = "10.0.1.0/24"
  vnet    = proxmox_virtual_environment_sdn_vnet.public.id
  gateway = "10.0.1.1"
  snat    = true # Source NAT enabled (acts like Internet Gateway / NAT gateway)

  dhcp_range = {
    start_address = "10.0.1.10"
    end_address   = "10.0.1.200"
  }
}

# Private Subnet IP configuration: SNAT is disabled (totally private)
resource "proxmox_virtual_environment_sdn_subnet" "private_subnet" {
  cidr    = "10.0.2.0/24"
  vnet    = proxmox_virtual_environment_sdn_vnet.private.id
  gateway = "10.0.2.1"
  snat    = false # Private subnet (no direct outbound internet access)

  dhcp_range = {
    start_address = "10.0.2.10"
    end_address   = "10.0.2.200"
  }
}

# SDN Applier: Applies/commits the SDN network configurations to the cluster
resource "proxmox_virtual_environment_sdn_applier" "apply" {
  depends_on = [
    proxmox_virtual_environment_sdn_subnet.public_subnet,
    proxmox_virtual_environment_sdn_subnet.private_subnet
  ]
}


# ==============================================================================
# 2. FIREWALL SECURITY GROUPS
# ==============================================================================

# Bastion Security Group: Allows SSH from anywhere
resource "proxmox_virtual_environment_cluster_firewall_security_group" "bastion" {
  name    = "bastion-sg"
  comment = "AWS-style Bastion security group"

  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    comment = "Allow SSH from anywhere"
  }
}

# Private App Security Group: Restricts traffic to the public subnet only
resource "proxmox_virtual_environment_cluster_firewall_security_group" "private_app" {
  name    = "private-app-sg"
  comment = "AWS-style Private App security group"

  # Allow Database access (Port 5432) only from the Public Subnet (10.0.1.0/24)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "5432"
    source  = "10.0.1.0/24"
    comment = "Allow PostgreSQL only from public subnet"
  }

  # Allow SSH access only from the Public Subnet (10.0.1.0/24)
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "22"
    source  = "10.0.1.0/24"
    comment = "Allow SSH only from public subnet"
  }
}


# ==============================================================================
# 3. VIRTUAL MACHINES (COMPUTE INSTANCES)
# ==============================================================================

# Bastion Host (Public Subnet Instance)
resource "proxmox_virtual_environment_vm" "bastion" {
  name      = "bastion-host"
  node_name = "r620"
  vm_id     = 8100
  tags      = ["vpc-demo", "public-subnet"]

  # Ensure networks are applied before creating VMs
  depends_on = [proxmox_virtual_environment_sdn_applier.apply]

  clone {
    vm_id        = 80801 # Ubuntu template ID
    datastore_id = "local-zfs"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 30
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = 2048
  }

  cpu {
    cores = 2
  }

  # Attach VM interface to the Public VNet and enable Proxmox Firewall
  network_device {
    bridge   = proxmox_virtual_environment_sdn_vnet.public.id
    firewall = true
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "10.0.1.10/24"
        gateway = "10.0.1.1"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.RSA_PUB]
    }
  }
}

# App Server (Private Subnet Instance)
resource "proxmox_virtual_environment_vm" "app_server" {
  name      = "app-server"
  node_name = "r620"
  vm_id     = 8200
  tags      = ["vpc-demo", "private-subnet"]

  # Ensure networks are applied before creating VMs
  depends_on = [proxmox_virtual_environment_sdn_applier.apply]

  clone {
    vm_id        = 80801 # Ubuntu template ID
    datastore_id = "local-zfs"
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 30
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = 2048
  }

  cpu {
    cores = 2
  }

  # Attach VM interface to the Private VNet and enable Proxmox Firewall
  network_device {
    bridge   = proxmox_virtual_environment_sdn_vnet.private.id
    firewall = true
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "10.0.2.10/24"
        gateway = "10.0.2.1"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.RSA_PUB]
    }
  }
}


# ==============================================================================
# 4. ASSOCIATE SECURITY GROUPS TO VIRTUAL MACHINES
# ==============================================================================

resource "proxmox_virtual_environment_firewall_rules" "bastion_rules" {
  node_name = proxmox_virtual_environment_vm.bastion.node_name
  vm_id     = proxmox_virtual_environment_vm.bastion.vm_id

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.bastion.name
    comment        = "Apply bastion security group"
    iface          = "net0"
  }
}

resource "proxmox_virtual_environment_firewall_rules" "app_server_rules" {
  node_name = proxmox_virtual_environment_vm.app_server.node_name
  vm_id     = proxmox_virtual_environment_vm.app_server.vm_id

  rule {
    security_group = proxmox_virtual_environment_cluster_firewall_security_group.private_app.name
    comment        = "Apply private app security group"
    iface          = "net0"
  }
}
