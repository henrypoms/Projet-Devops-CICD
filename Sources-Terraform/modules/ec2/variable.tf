variable "maintainer" {
  type    = string
  default = "ulrich"
}

variable "instance_type" {
  type    = string
  default = "t2.nano"
}


variable "vpc_id" {
  description = "The ID of VPC in which to create ec2 instance."
  default     = "sg-014762743ac0ae048"

}

variable "ssh_key" {
  type    = string
  default = "devops-henry"
}

variable "sg_name" {
  type    = string
  default = "NULL"
}

variable "server_name" {
  type    = string
  default = "NULL"
}

variable "public_ip" {
  type    = string
  default = "NULL"
}

variable "projet_name" {
  type    = string
  default = "ic-webapp"
}

variable "AZ" {
  type    = string
  default = "us-east-1a"
}

variable "user" {
  type    = string
  default = "ec2-user"
}
