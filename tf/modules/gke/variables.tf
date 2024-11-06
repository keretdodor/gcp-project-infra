variable "region" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "machine_type" {
   description = "The region the architucture will be deployed on"
   type        = string
}

variable "vpc_name" {
   description = "VPC name"
   type        = string
}

variable "private_subnet" {
   description = "private subnet's name"
   type        = string
}

variable "pod_range_name" {
  description = "The name of the secondary IP range for pods."
  type        = string
}

variable "service_range_name" {
  description = "The name of the secondary IP range for services."
  type        = string
}