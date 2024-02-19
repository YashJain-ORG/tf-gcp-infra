provider "google" {
  credentials = file(var.credentials_File)
  project     = var.project_Id
  region      = var.region
}

locals {
  vpc_names = [for i in range(var.number_vpcs) : "csye-vpc-${i}"]
}

resour "google_compute_network" "vpc" {
  count                           = var.number_vpcs
  name                            = "csye-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
  count   = var.number_vpcs * var.number_webapp_subnets_per_vpc
  name    = "webapp-${count.index}"
  region  = var.region
  network = google_compute_network.vpc[floor(count.index / var.number_webapp_subnets_per_vpc)].self_link
  # ip_cidr_range = var.webapp_Subnet_Cidr
  ip_cidr_range = "10.${count.index}.0.0/24"

}

resource "google_compute_subnetwork" "db_subnet" {

  count   = var.number_vpcs * var.number_db_subnets_per_vpc
  name    = "db-${count.index}"
  region  = var.region
  network = google_compute_network.vpc[floor(count.index / var.number_db_subnets_per_vpc)].self_link
  # ip_cidr_range = var.db_Subnet_Cidr
  ip_cidr_range = "10.${count.index + 100}.0.0/24"
}

resource "google_compute_route" "webapp_route" {
  count            = var.number_vpcs
  name             = "webapp-route-${count.index}"
  network          = google_compute_network.vpc[count.index].self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["webapp"]
}
