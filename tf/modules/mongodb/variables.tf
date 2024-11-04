variable "region" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "machine_type" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "private_subnet_name" {
   description = "private subnet's name"
   type        = string
}

variable "bastion_ip" {
   description = "Bastion's host ip's"
   type        = string
}

variable "vpc_name" {
   description = "VPC name"
   type        = string
}

