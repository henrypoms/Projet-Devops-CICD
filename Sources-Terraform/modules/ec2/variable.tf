variable "maintainer" {
  type    = string
  default = "ulrich"
}

variable "vpc_id" {
  type = string 
  id = "vpc-09d6da5e18e139a5d"
}

variable "instance_type" {
  type    = string
  default = "t2.nano"
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
  default = "us-east-1b"
}

variable "user" {
  type    = string
  default = "ec2-user"
}
