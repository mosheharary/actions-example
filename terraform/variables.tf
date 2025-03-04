variable "app_name" {
  description = "The name of the application"
  default     = "sample-app"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  default     = "sample-app-key-name"
  description = "AWS Key Pair name to access the instance"
}