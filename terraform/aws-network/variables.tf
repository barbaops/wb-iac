variable "project_name" {
  type        = string
  description = "Nome do projeto"
}

variable "vpc_cidr" {
  type    = string
  default = "CIDR principal da VPC"
}

variable "dns_hostnames" {
  type    = bool
  default = true
}

variable "dns_support" {
  type    = bool
  default = true
}

variable "vpc_additional_cidrs" {
  type        = list(string)
  description = "Lista de CIDR's adicionais da VPC"
  default     = []
}

variable "public_subnets" {
  description = "Lista de Public Subnets da VPC"
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Lista de Private Subnets da VPC"
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
}

variable "database_subnets" {
  description = "Lista de Database Subnets da VPC"
  default     = []
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
}