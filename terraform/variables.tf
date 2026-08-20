variable vpc_cidr_block {
  default = "10.0.0.0/16"
}
variable subnet_cidr_block {
  default = "10.0.10.0/24"
}
variable avail_zone {
  default = "ap-southeast-2b"
}
variable env_prefix {
  default = "dev"
}
variable project_name_prefix {
    default = "tf-jenkins-1"
}
variable instance_type {
    default = "t3.micro"
}
variable region {
    default = "ap-southeast-2"
}
variable "key_name" {
  type = string
}
