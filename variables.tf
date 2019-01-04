variable "v_pm-api-url" {
	description = "Proxmox API URL"
	default = "https://10.200.1.4:8006/api2/json"
}

variable "v_pm-user" {
	description = "Proxmox provisioning user"
	default = "terraform@pve"
}

variable "v_pm-pass" {
	description = "Proxmox provisioning pass"
	default = "t3rraf0rm"
}
