# all the clones for use:

# "ubuntu" = 80801
# "k3s"    = 80901
# "debian" = 81001


# all the conif that can be on vm:

# module "test_vm" {
#   source = "../../modules/proxmox/vm"

#   target_node = "r620"

#   on_boot = true
#   started = true

#   vm_replica = 1

#   vm_name  = "exmp"
#   vm_id = 120
#   tags  = ["demo machine"]

#   cores     = 4
#   memory = 4096
#   storage      = 30

#   ip = "dhcpע"

# }

# the minimum is vm_id for the machine.

module "open_claw" {
    source = "../../modules/proxmox/vm"
    vm_id = 42001
    vm_name = "open-claw"
}

