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

variable "routes" {
  type = map(object({
    dest_range       = string
    next_hop_gateway = string
    priority         = number
    tags             = list(string)
  }))
  default = {
    webapp = {
      dest_range       = "0.0.0.0/0"
      next_hop_gateway = "default-internet-gateway" // You can replace this with the appropriate gateway name
      priority         = 1000
      tags             = ["webapp"]
    }
  }
}

variable "db_user" {
  default = "webapp"

}
variable "db_dialect" {
  default = "mysql"

}
variable "db_name" {
  default = "webapp"

}

variable "my_port" {
  default = "3306"

}
