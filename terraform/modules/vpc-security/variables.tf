variable "admin_cidr" {
  description = "Admin IP CIDR voor directe beheer en web dashboards (Grafana/Shuffle)"
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

variable "branch_cidr" {
  description = "CIDR block van Branch Office VPC"
  type        = string
  default     = "192.168.0.0/16"
}
