data "template_file" "cn_agent" {
  template = file("${path.module}/templates/cn_agent.sh")

  vars = {
    consul_version = "1.8.2"
    consul_name    = "gcp_agent"
    datacenter     = "gcp"
    credentials    = var.credentials == "" ? file(var.credentials_file) : var.credentials
    gcp_project    = google_compute_instance.consul_server.project
    gcp_zone       = google_compute_instance.consul_server.zone
    servername     = google_compute_instance.consul_server.name
    serverip       = google_compute_instance.consul_server.network_interface.0.network_ip
    public_ip      = google_compute_address.cn_agent_public_ip.address
  }
}

resource "google_compute_address" "cn_agent_public_ip" {
  name = "${var.consul.agent}-public-ip"
}

resource "google_compute_instance" "cn_agent" {

  name         = var.consul.agent
  machine_type = "g1-small"
  tags         = [var.consul.agent]
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

  metadata_startup_script = data.template_file.cn_agent.rendered

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.cn_agent_public_ip.address
    }
  }
}

output "agent_public_ip" {
  value = google_compute_address.cn_agent_public_ip.address
}

output "agent_private_ip" {
  value = google_compute_instance.cn_agent.network_interface.0.network_ip
}
