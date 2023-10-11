variable "cidr-block" {
  default = "172.0.0.0/16"
}

variable "subnet-cidr-prefix" {
  default = "172.0"
}

variable "public-subnet-count" {
  default = 2
}

variable "private-subnet-count" {
  default = 2
}

variable "dns-host-name" {
  default = true
}
variable "enable-dns-support" {
  default = true
}

variable "availability_zones" {}

variable "resource-prefix" {}
