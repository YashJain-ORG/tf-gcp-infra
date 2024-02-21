variable "credentials_File" {
  default = "terraform-with-gcp-414418-a3b942c9e1ca.json"
}

variable "project_Id" {
  default = "terraform-with-gcp-414418"
}

variable "region" {
  default = "us-east1"
}

variable "webapp_Subnet_Cidr" {
  default = "10.0.0.0/24"
}

variable "db_Subnet_Cidr" {
  default = "10.0.1.0/24"
}

variable "number_vpcs" {
  description = "Number of VPCs to create"
  default     = "1"
}

variable "number_webapp_subnets_per_vpc" {
  description = "Number of subnets to create per VPC"
  default     = "1"
}

variable "number_db_subnets_per_vpc" {
  description = "Number of subnets to create per VPC"
  default     = "1"
}
