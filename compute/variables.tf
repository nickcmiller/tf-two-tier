# compute/variables.tf

variable "instance_count" {
    type = number
} #1
variable "instance_type" {
    type = string
} #t3.micro
variable "public_subnets" {
    type = list
}
variable "public_security_group" {
    type = string
}
variable "volume_size" {
    type = number 
} #10