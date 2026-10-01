variable "web_vpc_id" { type = string }
variable "web_subnet_ids" { type = list(string) }
variable "web_route_table_id" { type = string }
variable "web_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "data_vpc_id" { type = string }
variable "data_subnet_ids" { type = list(string) }
variable "data_route_table_id" { type = string }
variable "data_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "hub_vpc_id" { type = string }
variable "hub_subnet_ids" { type = list(string) }
variable "hub_route_table_id" { type = string }
variable "hub_cidr" {
  type    = string
  default = "10.2.0.0/16"
}