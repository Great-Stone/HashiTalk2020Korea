data "template_file" "cn_server" {
  template = file("${path.module}/templates/cn_server.sh")

  vars = {
    consul_version = "1.8.2"
    consul_name    = "gcp_server"
    datacenter     = "gcp"
    region         = var.gcp.region
    public_ip      = google_compute_address.cn_server_public_ip.address
  }
}

resource "google_compute_address" "cn_server_public_ip" {
  name = "${var.consul.server}-public-ip"
}

resource "google_compute_instance" "consul_server" {

  name         = var.consul.server
  machine_type = "g1-small"
  tags         = [var.consul.server]
  zone         = var.gcp.zone
  labels       = var.tag

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  metadata = {
    owner = "gs@hashicorp.com"
  }

  metadata_startup_script = data.template_file.cn_server.rendered

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.cn_server_public_ip.address
    }
  }
}

output "server_public_ip" {
  value = google_compute_address.cn_server_public_ip.address
}

output "server_private_ip" {
  value = google_compute_instance.consul_server.network_interface.0.network_ip
}
