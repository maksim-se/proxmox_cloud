provider "proxmox" {
	pm_tls_insecure = true
	pm_api_url = "${var.v_pm-api-url}"
	pm_user = "${var.v_pm-user}"
	pm_password = "${var.v_pm-pass}"
}

resource "proxmox_vm_qemu" "cluster" {

	# nodes description
	count = 1
	name = "kube-${count.index + 1}"
	desc = "kubernetes cluster"
	target_node = "bve"
	clone = "centos7-ci-hm"
	os_type = "centos"
	onboot = "true"

	# node hardware
	cores = 2
	sockets = 1
	memory = 2048
	disk {
		id = "0"
		storage = "data-hdd"
		type = "scsi"
		size = "20G"
	}
	
	# node connectivity
	network {
		id = 0
		model = "virtio"
		bridge = "vmbr0"
		firewall = "false"
		link_down = "false"
	}
	#ipconfig0 = "ip=169.254.1.1/32"
	#ipconfig0 = "ip=dhcp"
	#ipconfig1 = "ip=dhcp"
	ssh_forward_ip = "10.200.1.4"
	ssh_user = "centos"
	ssh_private_key = "${file("~/.ssh/id_rsa")}"
	sshkeys = "${file("~/.ssh/id_rsa.pub")}"

  #provisioner "file" {
	#	source      = "script.sh"
	#	destination = "/tmp/script.sh"
	#}

	#provisioner "remote-exec" {
	#	inline = [
	#		"chmod +x /tmp/script.sh",
	#		"/tmp/script.sh args",
	#	]
	#}

	provisioner "remote-exec" {
		inline = [
			"/usr/sbin/ip addr"
		]
	}

	provisioner "proxmox" {
		action = "sshbackward"
	}

}
