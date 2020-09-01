// data "template_file" "consul_gmw" {
//   template = file("${path.module}/templates/consul_mgw.sh")

//   vars = {
//     consul_version = "1.8.2"
//     consul_name    = "gcp_mesh_gw"
//     datacenter     = "gcp"
//     credentials    = var.credentials == "" ? file(var.credentials_file) : var.credentials
//     gcp_project    = google_compute_instance.consul_server.project
//     gcp_zone       = google_compute_instance.consul_server.zone
//     servername     = google_compute_instance.consul_server.name
//     serverip       = google_compute_instance.consul_server.network_interface.0.network_ip
//     public_ip      = google_compute_address.consul_gmw_public_ip.address
//   }
// }

// resource "google_compute_address" "consul_gmw_public_ip" {
//   name = "${var.consul.meshgw}-public-ip"
// }

// resource "google_compute_instance" "consul_gmw" {

//   name         = var.consul.meshgw
//   machine_type = "f1-micro"
//   tags         = [var.consul.meshgw]
//   zone         = var.gcp.zone
//   labels       = var.tag

//   boot_disk {
//     initialize_params {
//       image = "debian-cloud/debian-10"
//     }
//   }

//   metadata = {
//     owner = "gs@hashicorp.com"
//   }

//   metadata_startup_script = data.template_file.consul_gmw.rendered

//   network_interface {
//     network = "default"
//     access_config {
//       nat_ip = google_compute_address.consul_gmw_public_ip.address
//     }
//   }
// }

// output "mgw_public_ip" {
//   value = google_compute_address.consul_gmw_public_ip.address
// }

// output "mgw_private_ip" {
//   value = google_compute_instance.consul_gmw.network_interface.0.network_ip
// }
