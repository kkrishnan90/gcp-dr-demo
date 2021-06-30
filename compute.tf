######### PROVISION API/APPLICATION LAYER ####################
resource "google_compute_instance" "vm_api_instance" {
  name         = "delhi-api-instance-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  machine_type = "f1-micro"
  project      = var.project
  zone         = var.zone
  depends_on = [
    google_sql_database_instance.read_replica
  ]
  boot_disk {
    initialize_params {
      image = "projects/demo-project/global/images/mumbai-api-instance-image"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.user
      timeout     = "500s"
      private_key = file(var.ssh_private_key_path)
    }
    inline = [
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"SQL instance created...\"}'",
      "sleep 5s",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Creating API instance...\"}'",
      "echo ${google_sql_database_instance.read_replica.private_ip_address} >> dbconfig.txt",
      "export DB_HOST=${google_sql_database_instance.read_replica.private_ip_address}",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Writing DB Configuration...\"}'",
      "echo export DB_HOST=${google_sql_database_instance.read_replica.private_ip_address} >> ~/.bashrc",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Starting API service...\"}'",
      "forever start /home/kkrish/api/app.js",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"API Creation Completed...\"}'"
    ]
  }
  service_account {
    email  = var.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.user}:${file(var.ssh_public_key_path)}"
  }
}

output "api-server-ip-address" {
  value = google_compute_instance.vm_api_instance.network_interface[0].access_config[0].nat_ip
}



######### PROVISION WEB FLUTTER LAYER ####################
resource "google_compute_instance" "vm_web_instance" {
  name         = "delhi-web-instance-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  machine_type = "f1-micro"
  project      = var.project
  zone         = var.zone
  depends_on = [
    google_sql_database_instance.read_replica,
    google_compute_instance.vm_api_instance
  ]
  boot_disk {
    initialize_params {
      image = "projects/demo-project/global/images/mumbai-app-instance-image"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = self.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.user
      timeout     = "500s"
      private_key = file(var.ssh_private_key_path)
    }
    inline = [
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Starting Web Application instance...\"}'",
      "echo ${google_compute_instance.vm_api_instance.network_interface[0].access_config[0].nat_ip} >> env.txt",
      "sleep 3s",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Writing API layer configuration...\"}'",
      "sudo truncate -s 0 /var/www/html/assets/.env",
      "echo 'DELHI=TRUE' | sudo tee -a /var/www/html/assets/.env",
      "echo 'DELHI_API_HOST=${google_compute_instance.vm_api_instance.network_interface[0].access_config[0].nat_ip}' | sudo tee -a /var/www/html/assets/.env",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Promoting SQL replica to master...\"}'",
      //Promote read replica to master
      "gcloud sql instances promote-replica ${google_sql_database_instance.read_replica.name} --quiet",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Promoted SQL replica to master...\"}'",
      "sleep 3s",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Web Application Creation Completed...\"}'",
      "sleep 3s",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"Configuring DNS records...\"}'",
      //Delete any existing DNS records
      "gcloud dns record-sets delete corp-ce.com. --type=A --zone=corp-ce-com",
      "sleep 5s",
      "gcloud pubsub topics publish dr-status --message='{\"status\":\"DR setup completed successfully...\"}'"
    ]
  }


  service_account {
    email  = var.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.user}:${file(var.ssh_public_key_path)}"
  }
}

output "web-server-ip-address" {
  value = google_compute_instance.vm_web_instance.network_interface[0].access_config[0].nat_ip
}


resource "google_dns_record_set" "resource-recordset" {
  provider     = "google-beta"
  managed_zone = "corp-ce-com"
  name         = "corp-ce.com."
  type         = "A"
  rrdatas      = ["${google_compute_instance.vm_web_instance.network_interface[0].access_config[0].nat_ip}"]
  ttl          = 300
  depends_on = [
    google_sql_database_instance.read_replica, google_compute_instance.vm_api_instance, google_compute_instance.vm_api_instance
  ]
}
