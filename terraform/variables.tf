variable "app_name" {
  description = "The name of the application"
  default     = "sample-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "private_key" {
  description = "The private key to access the EC2 instance"
  sensitive   = true
}

variable "public_key" {
  description = "The public key for the EC2 instance"
}