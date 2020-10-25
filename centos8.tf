variable "vm_name" {
  type = string
  default = "my-test-vm"
}

variable "domain" {
  type = string
  default = "example.com"
}

variable "memory" {
  type = string
  default = "2048"
}

variable "cpu" {
  type = number
  default = 2
}

provider "libvirt" {
  uri = "qemu:///system"
}


resource "libvirt_volume" "qcow_volume" {
  name = "${var.vm_name}.img"
  pool = "default"
  source = "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")

  vars = {
   hostname = var.vm_name
   domain = var.domain
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  pool           = "default"
}

# Define KVM domain to create
resource "libvirt_domain" "kvm_domain" {
  name   = var.vm_name
  memory = var.memory
  vcpu   = var.cpu

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.qcow_volume.id
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }
}

output "ip" {
  value = libvirt_domain.kvm_domain.network_interface.0.addresses.0
}

