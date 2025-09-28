terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

variable "proxmox_api_url" {
  description = "Proxmox API endpoint, e.g. https://proxmox.example.local:8006/api2/json"
  type        = string
}

variable "proxmox_node_id" {
  description = "ID of worker node"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox username with API privileges, e.g. root@pam or svc-terraform@pve"
  type        = string
  default     = "terraform"
}

variable "proxmox_password" {
  description = "Proxmox password or API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The Proxmox cluster node name to provision the VMs on"
  type        = string
}

variable "template_vm_id" {
  description = "VMID of an existing Alpine cloud-init template in Proxmox"
  type        = number
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

# Master VM (2 core, 4 GB)
resource "proxmox_vm_qemu" "master" {
  name        = "alpine-k8s-master-${var.proxmox_node_id}"
  target_node = var.proxmox_node

  clone      = var.template_vm_id
  full_clone = true

  cores   = 2
  sockets = 1
  memory  = 4096

  scsihw = "virtio-scsi-pci"
  disk {
    size         = "24G"
    type         = "scsi"
    storage      = var.vm_storage
    storage_type = "lvm"
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  agent     = 1
  ciuser    = "root"
  sshkeys  = var.ssh_public_key
  ipconfig0 = "ip=dhcp"
}

# Worker VMs (each 1 core, 2 GB)
resource "proxmox_vm_qemu" "worker" {
  count       = 2
  name        = "alpine-k8s-worker-${var.proxmox_node_id}0${count.index + 1}"
  target_node = var.proxmox_node

  clone      = var.template_vm_id
  full_clone = true

  cores   = 1
  sockets = 1
  memory  = 2048

  scsihw = "virtio-scsi-pci"
  disk {
    size         = "16G"
    type         = "scsi"
    storage      = var.vm_storage
    storage_type = "lvm"
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  agent     = 1
  ciuser    = "root"
  sshkeys  = var.ssh_public_key
  ipconfig0 = "ip=dhcp"
}

output "master_vmid" {
  description = "VMID assigned to the master VM"
  value       = proxmox_vm_qemu.master.vmid
}

output "master_name" {
  description = "Name of the master VM"
  value       = proxmox_vm_qemu.master.name
}

output "worker_vmids" {
  description = "List of VMIDs assigned to worker VMs"
  value       = [for w in proxmox_vm_qemu.worker : w.vmid]
}

output "worker_names" {
  description = "List of worker VM names"
  value       = [for w in proxmox_vm_qemu.worker : w.name]
}
