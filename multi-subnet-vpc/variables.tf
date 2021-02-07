variable "my_ip" {
  description = "Your public IP"
  type        = string
  default     = "86.13.240.179"
}

variable "key_pair_name" {
  description = "AWS keypair name"
  type = string
  default = "atd_keypair"
}
