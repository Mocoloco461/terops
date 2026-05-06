module "test_vm" {
  source = "./modules/proxmox/vm" 
  vm_id = 1000
  tags = ["lab"]
  
}