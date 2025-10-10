module proxmox-k3s {
  source = "../proxmox-k3s"
  proxmox_node_id = "2"
  proxmox_password = var.proxmox_password
}

variable "proxmox_password" {
  description = "Proxmox password or API token secret"
  type        = string
  sensitive   = true
}
