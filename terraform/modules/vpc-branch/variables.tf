variable "admin_cidr" {
  description = "Admin IP CIDR voor direct beheer"
  type        = string
}

variable "key_name" {
  description = "SSH Key Pair naam voor EC2 instances"
  type        = string
  default     = "bastion-key"
}

variable "hub_cidr" {
  description = "CIDR block van Hub VPC (Bastion/Ansible)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "security_cidr" {
  description = "CIDR block van Security VPC (SOAR mitigatie/promtail)"
  type        = string
  default     = "10.3.0.0/16"
}
