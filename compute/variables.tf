# compute/variables.tf
variable "vpc_id" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "instance_type" {
  type = string
} #t3.micro
variable "public_subnets" {
  type = list(any)
}
variable "public_security_group" {
  type = string
}
variable "web_subnets" {
  type = list(any)
}
variable "web_security_group" {
  type = string
}
variable "volume_size" {
  type = number
} #10