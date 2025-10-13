module proxmox-k3s {
  source = "../proxmox-k3s"
  proxmox_node_id = "1"
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
