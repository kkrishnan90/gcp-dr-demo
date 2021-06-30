resource "google_sql_database_instance" "read_replica" {
  name                 = "tf-replica-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  database_version     = "MYSQL_5_7"
  region               = var.region
  project              = var.project
  master_instance_name = "tf-primary"
  replica_configuration {
    failover_target = false
  }
  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = true
      private_network = "projects/${var.project}/global/networks/default"
    }
  }


}
output "database_private_ip" {
  value = google_sql_database_instance.read_replica.private_ip_address
}
