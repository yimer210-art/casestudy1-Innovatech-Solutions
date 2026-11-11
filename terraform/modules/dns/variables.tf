variable "hub_vpc_id" { type = string }
variable "web_vpc_id" { type = string }
variable "data_vpc_id" { type = string }
variable "security_vpc_id" { type = string }
variable "branch_vpc_id" { type = string }

variable "security_ip" {
  description = "Private IP van de Security Stack (10.3.1.50)"
  type        = string
  default     = "10.3.1.50"
}

variable "workstation_ip" {
  description = "Private IP van Workstation 01 (192.168.56.10)"
  type        = string
  default     = "192.168.56.10"
}

variable "branch_server_ip" {
  description = "Private IP van Branch Server 01 (192.168.56.20)"
  type        = string
  default     = "192.168.56.20"
}

variable "attacker_ip" {
  description = "Private IP van Attacker Node (192.168.56.30)"
  type        = string
  default     = "192.168.56.30"
}
