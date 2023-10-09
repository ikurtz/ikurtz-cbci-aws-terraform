variable "cidr-block" {
  default = "10.0.0.0/16"
}

variable "subnet-cidr-prefix" {
  default = "0.0"
}

variable "public-subnet-count" {
  default = 1
}

variable "private-subnet-count" {
  default = 1
}

variable "dns-host-name" {
  default = true
}
variable "enable-dns-support" {
  default = true
}

variable "availability_zones" {}

variable "resource-prefix" {}