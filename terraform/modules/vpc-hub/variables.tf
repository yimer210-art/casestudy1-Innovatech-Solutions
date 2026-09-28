variable "admin_cidr" {
  description = "IP-adres (of bereik) waarvandaan beheerders via SSH mogen inloggen"
  type        = string
}

variable "bastion_public_key" {
  description = "Publieke SSH-sleutel voor de Bastion Host"
  type        = string
}