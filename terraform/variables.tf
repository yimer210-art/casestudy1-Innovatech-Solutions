variable "db_password" {
  type      = string
  sensitive = true
}

variable "admin_cidr" {
  type = string
}

variable "bastion_public_key" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}