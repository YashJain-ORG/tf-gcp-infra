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

# resource "google_compute_instance" "vm_instance_webapp" {
#   name         = "ass4-instance"
#   machine_type = "n1-standard-1"
#   zone         = "us-central1-c"

#   boot_disk {
#     initialize_params {
#       image = "projects/${var.project_id}/global/images/${var.image_name}"
#       size  = "100"
#       type  = "pd-standard"
#     }
#   }

#   network_interface {
#     network    = google_compute_network.my-vpc.self_link
#     subnetwork = google_compute_subnetwork.webapp.self_link
#     access_config {
#     }
#   }
#   tags = ["webapp"]

#   service_account {
#     email  = google_service_account.service_account.email
#     scopes = ["cloud-platform"]
#   }

#   metadata_startup_script = <<-SCRIPT
#     sudo bash -c 'cat > /opt/csye6225/webapp/.env <<EOT
#     DB_USER=webapp
#     DB_DIALECT=mysql
#     DB_NAME=webapp
#     DB_PASSWORD=${google_sql_user.new_user.password}
#     DB_HOST=${google_sql_database_instance.my-sql.private_ip_address}
#     PORT=3306
#     EOT'
#   SCRIPT
# }
resource "google_sql_database_instance" "my-sql" {

  name                = "my-sql"
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-n1-standard-1"
    # tier              = "db-f1-micro"
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

resource "google_dns_record_set" "dns_record" {
  name         = "thewebapp.me."
  type         = "A"
  ttl          = 300
  managed_zone = "us-central1-c"
  //rrdatas      = [google_compute_instance.vm_instance_webapp.network_interface[0].access_config[0].nat_ip]
  rrdatas = [google_compute_global_address.default.address]
}

# Create a service account
resource "google_service_account" "service_account" {
  account_id   = "webapp-service-account-id"
  display_name = "webapp-service-account"
}
resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role    = "roles/logging.admin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "monitoring_admin_binding" {
  project = var.project_id
  role    = "roles/monitoring.admin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_pubsub_topic" "verify_email" {
  name = "verify_email"

  message_retention_duration = "604800s"
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name  = "verify_email_subscription"
  topic = google_pubsub_topic.verify_email.id

}

resource "google_pubsub_subscription_iam_binding" "webapp_subscription_binding" {
  project      = var.project_id
  subscription = google_pubsub_subscription.verify_email_subscription.name
  role         = "roles/pubsub.subscriber"
  members      = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-con"
  ip_cidr_range = "10.0.0.0/28"
  network       = google_compute_network.my-vpc.self_link

  machine_type  = "e2-standard-4"
  min_instances = 2
  max_instances = 3
}

resource "google_storage_bucket" "yash-webapp-bucket-6225" {
  name     = "yash-webapp-bucket-6225"
  location = "US"
}

resource "google_storage_bucket_object" "archive" {
  name   = "index.zip"
  bucket = google_storage_bucket.yash-webapp-bucket-6225.name
  source = "/Users/yashsmac/desktop/function-source.zip"
}

resource "google_project_iam_binding" "publisher_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_project_iam_binding" "publisher_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_cloudfunctions2_function" "cloud_function" {
  name        = "cloud_function"
  location    = "us-central1"
  description = "a new function"
  build_config {
    runtime     = "nodejs18"
    entry_point = "sendEmail"
    source {
      storage_source {
        bucket = google_storage_bucket.yash-webapp-bucket-6225.name
        object = google_storage_bucket_object.archive.name
      }
    }
    environment_variables = {
      DB_USER     = var.db_user
      DB_DIALECT  = var.db_dialect
      DB_NAME     = var.db_name
      DB_PASSWORD = google_sql_user.new_user.password
      DB_HOST     = google_sql_database_instance.my-sql.private_ip_address

    }
  }
  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60

    environment_variables = {
      DB_USER     = var.db_user
      DB_DIALECT  = var.db_dialect
      DB_NAME     = var.db_name
      DB_PASSWORD = google_sql_user.new_user.password
      DB_HOST     = google_sql_database_instance.my-sql.private_ip_address

    }

    vpc_connector = google_vpc_access_connector.connector.name
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}


# *****************************************************************************

resource "google_compute_instance_template" "webapp_template" {
  name         = "ass4-instance"
  machine_type = "n1-standard-1"
  region       = var.region

  disk {
    source_image = "projects/${var.project_id}/global/images/${var.image_name}"
    disk_type    = "pd-standard"
    disk_size_gb = 100
    mode         = "READ_WRITE"
  }

  metadata = {
    startup-script = <<-SCRIPT
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

  network_interface {
    network    = google_compute_network.my-vpc.self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["allow-health-check", "webapp"]
}

# [START cloudloadbalancing_ext_http_gce_instance_mig]
resource "google_compute_region_instance_group_manager" "default" {
  name               = "lb-backend-example"
  base_instance_name = "webapp"
  region             = var.region
  named_port {
    name = "http"
    port = 3000
  }
  version {
    instance_template = google_compute_instance_template.webapp_template.id
    name              = "primary"
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 300
  }

}
# [END cloudloadbalancing_ext_http_gce_instance_mig]

# [START cloudloadbalancing_ext_http_gce_instance_firewall_rule]
resource "google_compute_firewall" "default" {
  name          = "fw-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.my-vpc.self_link
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
  allow {
    ports    = ["3000", "8080", "22"]
    protocol = "tcp"
  }
}
# [END cloudloadbalancing_ext_http_gce_instance_firewall_rule]

# [START cloudloadbalancing_ext_http_gce_instance_ip_address]
resource "google_compute_global_address" "default" {
  name       = "lb-ipv4-1"
  ip_version = "IPV4"
}
# [END cloudloadbalancing_ext_http_gce_instance_ip_address]

resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "my-region-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 40

    cpu_utilization {
      target = 0.05
    }
  }
}

# [START cloudloadbalancing_ext_http_gce_instance_health_check]
resource "google_compute_health_check" "default" {
  name    = "http-basic-check"
  project = var.project_id
  http_health_check {
    port         = 3000
    request_path = "/healthz"
  }
}
# [END cloudloadbalancing_ext_http_gce_instance_health_check]

resource "google_compute_managed_ssl_certificate" "lb_default" {
  provider = google-beta
  name     = "myservice-ssl-cert"
  project  = var.project_id

  managed {
    domains = ["thewebapp.me"]
  }
}

# [START cloudloadbalancing_ext_http_gce_instance_backend_service]
resource "google_compute_backend_service" "default" {
  name                            = "web-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.default.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  locality_lb_policy              = "ROUND_ROBIN"
  backend {
    group           = google_compute_region_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
# [END cloudloadbalancing_ext_http_gce_instance_backend_service]

# [START cloudloadbalancing_ext_http_gce_instance_url_map]
resource "google_compute_url_map" "default" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.default.id
}
# [END cloudloadbalancing_ext_http_gce_instance_url_map]

# [START cloudloadbalancing_ext_http_gce_instance_target_http_proxy]
resource "google_compute_target_https_proxy" "default" {
  name             = "http-lb-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_default.id]
}

# [END cloudloadbalancing_ext_http_gce_instance_target_http_proxy]

# [START cloudloadbalancing_ext_http_gce_instance_forwarding_rule]
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-content-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}
# [END cloudloadbalancing_ext_http_gce_instance_forwarding_rule]
