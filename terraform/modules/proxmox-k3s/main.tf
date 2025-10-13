# Master VM (2 core, 4 GB)
resource "proxmox_vm_qemu" "master" {
  name        = "alpine-k3s-master-${var.proxmox_node_id}0"
  target_node = "worker-${var.proxmox_node_id}"

  clone      = var.template_vm_id
  full_clone = true

  cpu { cores   = 2 }
  memory  = 4096

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  boot = "order=scsi0"

  disk {
    slot         = "scsi0"
    size         = "24G"
    storage      = "local-lvm"
  }

  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  agent     = 1
  ciuser    = "root"
  sshkeys   = var.ssh_public_key

  # (Optional) IP Address and Gateway
  ipconfig0 = "ip=10.12.41.${var.proxmox_node_id}0/16,gw=10.12.10.1"

  # (Optional) Name servers
  nameserver = "10.12.10.1"
}


# Worker VMs (each 1 core, 2 GB)
resource "proxmox_vm_qemu" "worker" {
  count       = 2
  name        = "alpine-k3s-worker-${var.proxmox_node_id}${count.index + 1}"
  target_node = "worker-${var.proxmox_node_id}"

  clone      = var.template_vm_id
  full_clone = true

  cpu { cores   = 1 }
  memory  = 2048

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  boot = "order=scsi0"

  disk {
    slot         = "scsi0"
    size         = "16G"
    storage      = "local-lvm"
  }

  network {
    id = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  agent     = 1
  ciuser    = "root"
  sshkeys   = var.ssh_public_key

  # (Optional) IP Address and Gateway
  ipconfig0 = "ip=10.12.41.${var.proxmox_node_id}${count.index + 1}/16,gw=10.12.10.1"

  # (Optional) Name servers
  nameserver = "10.12.10.1"
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
