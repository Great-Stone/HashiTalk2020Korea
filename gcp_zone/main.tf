// Configure the gcp provider
provider "google" {
  credentials = var.credentials == "" ? file(var.credentials_file) : var.credentials

  project = var.gcp.project
  region  = var.gcp.region
}

resource "google_compute_firewall" "default" {
  name    = "consul-server-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["consul-server"]
}