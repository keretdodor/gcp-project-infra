variable "region" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "machine_type" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "private_subnet" {
   description = "private subnet's name"
   type        = string
}

variable "bastion_prv_ip" {
   description = "Bastion's host ip's"
   type        = string
}

variable "bastion_pub_ip" {
   description = "Bastion's host ip's"
   type        = string
}

variable "vpc_name" {
   description = "VPC name"
   type        = string
}

variable "nat_router_id" {
  description = "ID of the NAT router"
  type        = string
}