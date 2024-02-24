provider "google" {
  project = var.project_id
  region  = var.region
}

# for firewall start
resource "google_compute_firewall" "allow_request" {

  for_each = google_compute_network.vpc
  name     = "allow-request"
  network  = each.value.self_link

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["${each.key}-webapp", "http-server"]
}

resource "google_compute_firewall" "deny_tcp" {
  for_each = google_compute_network.vpc
  name     = "deny-all"
  network  = each.value.self_link

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  deny {
    protocol = "udp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["${each.key}-webapp"]

}
# for firewall end

resource "google_compute_network" "vpc" {
  for_each                        = toset(["new-vpc"])
  name                            = each.key
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true

}

resource "google_compute_subnetwork" "webapp" {
  for_each      = google_compute_network.vpc
  name          = "${each.key}-webapp"
  ip_cidr_range = var.webapp_Subnet_Cidr
  network       = each.value.self_link
  region        = var.region
}

resource "google_compute_subnetwork" "db" {
  for_each      = google_compute_network.vpc
  name          = "${each.key}-db"
  ip_cidr_range = var.db_Subnet_Cidr
  network       = each.value.self_link
  region        = var.region
}

resource "google_compute_route" "webapp" {
  for_each         = google_compute_network.vpc
  name             = "${each.key}-route"
  dest_range       = "0.0.0.0/0"
  network          = each.value.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["${each.key}-webapp"]
}

resource "google_compute_instance" "vm_instance_webapp" {
  for_each     = google_compute_network.vpc
  name         = "ass4-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "projects/${var.project_id}/global/images/${var.image_name}"
      size  = "100"
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = each.value.self_link
    subnetwork = google_compute_subnetwork.webapp[each.key].self_link
    access_config {
    }
  }
  tags = ["${each.key}-webapp", "http-server"]
}
