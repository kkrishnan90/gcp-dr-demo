variable "ssh_public_key_path" {}

variable "ssh_private_key_path" {}

variable "email" {
  type = string
}

variable "user" {
  type = string
}

variable "project" {
  type    = string
  default = "demo-project"
}

variable "region" {
  type    = string
  default = "asia-south2"
}

variable "zone" {
  type    = string
  default = "asia-south2-a"
}
