provider "google" {
  project = var.project_id
  region  = var.region
}

# for firewall start
resource "google_compute_firewall" "allow_request" {

  name    = "allow-request"
  network = google_compute_network.my-vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080", "22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["webapp", "http-server"]
}

resource "google_compute_firewall" "deny_tcp" {
  name    = "deny-all"
  network = google_compute_network.my-vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # deny {
  #   protocol = "udp"
  #   ports    = ["22"]
  # }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["webapp"]

}
# for firewall end

resource "google_compute_network" "my-vpc" {

  name                            = "new-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true

}

resource "google_compute_subnetwork" "webapp" {

  name          = "webapp"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.my-vpc.self_link
  region        = var.region
}

resource "google_compute_subnetwork" "db" {

  name          = "db"
  ip_cidr_range = var.db_Subnet_Cidr
  network       = google_compute_network.my-vpc.self_link
  region        = var.region
}

resource "google_compute_route" "routes" {
  for_each         = var.routes
  name             = each.key
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.my-vpc.self_link
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = each.value.tags
}

resource "google_compute_instance" "vm_instance_webapp" {
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
    network    = google_compute_network.my-vpc.self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
    access_config {
    }
  }
  tags = ["webapp"]

  metadata_startup_script = <<-SCRIPT
    sudo bash -c 'cat > /opt/csye6225/webapp/.env <<EOT
    DB_USER=webapp
    DB_DIALECT=mysql
    DB_NAME=webapp
    DB_PASSWORD=${google_sql_user.new_user.password}
    DB_HOST=${google_sql_database_instance.my-sql.private_ip_address}
    PORT=3306
    EOT'
  SCRIPT
}
resource "google_sql_database_instance" "my-sql" {

  name                = "my-sql"
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    disk_autoresize   = true
    disk_type         = "PD_SSD"
    disk_size         = 100
    availability_type = "REGIONAL"


    // Enabling binary logging
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.my-vpc.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}

# [START compute_internal_ip_private_access]
resource "google_compute_global_address" "ip_private_address" {
  name         = "global-psconnect-ip"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING"
  network      = google_compute_network.my-vpc.self_link
  # address      = "10.3.0.5"
  ip_version    = "IPV4"
  prefix_length = 20
}
# [END compute_internal_ip_private_access]

resource "google_service_networking_connection" "private_vpc_connection" {


  network                 = google_compute_network.my-vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.ip_private_address.name]
}



//createing the Db for the webapp
resource "google_sql_database" "webapp_db" {
  name     = "webapp"
  instance = google_sql_database_instance.my-sql.name
}
resource "random_password" "password" {
  length  = 8
  special = true
  # override_special = "!#&()-_=+[]{}<>:?"
}

resource "google_sql_user" "new_user" {
  name     = "webapp"
  instance = google_sql_database_instance.my-sql.name
  password = random_password.password.result

  depends_on = [google_sql_database.webapp_db]
  lifecycle {
    ignore_changes = [password] # Ignore password changes once user is created
  }
}


