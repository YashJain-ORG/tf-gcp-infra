variable "credentials_File" {
  default = "assignment-04-414723-6080b9227630.json"
}

variable "project_id" {
  default = "assignment-04-414723"
}

variable "image_name" {
  default = "my-custom-image"
}

variable "region" {
  default = "us-central1"
}

variable "webapp_Subnet_Cidr" {
  default = "10.0.1.0/24"
}

variable "db_Subnet_Cidr" {
  default = "10.0.2.0/24"
}

variable "routing_mode" {
  default = "REGIONAL"
}
