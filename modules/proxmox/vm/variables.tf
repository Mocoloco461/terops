variable "template_name" {
  description = "The OS template to use (e.g., ubuntu, k3s)"
  type        = string
  default     = "ubuntu"
}


variable "vm_name" {
  description = "The name of the vm"
  type        = string
  default     = "im-a-default-vm"
}

variable "target_node" {
  description = ""
  type        = string
  default     = "r620"
}

variable "started" {
  description = ""
  type        = bool
  default     = true
}


variable "on_boot" {
  description = ""
  type        = bool
  default     = false
}


variable "vm_replica" {
  description = ""
  type        = number
  default     = 1
}


variable "tags" {
  description = ""
  type        = list(string)
  default = []
}

variable "vm_id" {
  description = ""
  type        = number
}


variable "storage" {
    description = "value"
    type = number
    default = 30
}

variable "memory" {
    description = "value"
    type = number
    default = 4096
}

variable "cores" {
    description = "value"
    type = number
    default = 4
  
}

variable "ip" {
    description = "ip"
    type = string
    default = "dhcp"
  
}

