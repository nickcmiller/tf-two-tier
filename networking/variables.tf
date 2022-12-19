variable "vpc_cidr" {
  type = string
}

variable "max_subnets" {
  type = number
}

variable "public_sn_count" {
  type = number
}

variable "web_sn_count" {
  type = number
}

variable "rds_sn_count" {
  type = number
}

variable "public_cidrs" {
  type = list(any)
}

variable "web_cidrs" {
  type = list(any)
}

variable "rds_cidrs" {
  type = list(any)
}