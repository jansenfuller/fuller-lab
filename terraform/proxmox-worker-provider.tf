terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://worker-${var.proxmox_node_id}.ff.home:8006/api2/json"
  pm_api_token_id     = "terraform@pve!tat"
  pm_api_token_secret = var.proxmox_password
  pm_tls_insecure     = true
}

variable "proxmox_node_id" {
  description = "ID of worker node"
  type        = number
}

variable "proxmox_password" {
  description = "Proxmox password or API token secret"
  type        = string
  sensitive   = true
}

variable "template_vm_id" {
  description = "Alpine cloud-init template name in Proxmox"
  type        = string
}

variable "vm_storage" {
  description = "Storage identifier for VM disk, e.g. local-lvm"
  type        = string
  default     = "local-lvm"
}

variable "vm_bridge" {
  description = "Network bridge to attach the VMs to, e.g. vmbr0"
  type        = string
  default     = "vmbr0"
}

variable "ssh_public_key" {
  description = "SSH public key to install in the VMs"
  type        = string
}
