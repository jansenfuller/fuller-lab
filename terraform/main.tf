module proxmox-k3s-worker-1 {
  source = "./modules/worker-1"
  proxmox_password = var.proxmox_password
  ssh_public_key = var.ssh_public_key
}

module proxmox-k3s-worker-2 {
  source = "./modules/worker-2"
  proxmox_password = var.proxmox_password
  ssh_public_key = var.ssh_public_key
}

module proxmox-k3s-worker-3 {
  source = "./modules/worker-3"
  proxmox_password = var.proxmox_password
  ssh_public_key = var.ssh_public_key
}

variable "proxmox_password" {
  description = "Proxmox password or API token secret"
  type        = string
  sensitive   = true
  default     = "no-password"
}

variable "ssh_public_key" {
  description = "Ansible SSH public key to install in the VMs"
  type        = string
  default     = "mod-no-key"
}
