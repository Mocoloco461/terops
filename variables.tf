#--- machines

variable "MASTER_COUNT" {
  type      = string
  sensitive = false
}

variable "WORKER_COUNT" {
  type      = string
  sensitive = false
}

variable "TURN_ON" {
  type      = string
  sensitive = false

}


#--- Proxmox
variable "API_TOKEN" {
  type      = string
  sensitive = true
}

variable "ENDPOINT" {
  type      = string
  sensitive = true
}


#--- SSH
variable "RSA_PUB" {
  type      = string
  sensitive = true
}
