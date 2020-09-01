variable "tag" {
  default = {
    tag_key   = "owner"
    tag_value = "gs@hashicorp.com"
  }
}

// Image list : ncloud server getServerImageProductList 
// Product list ex: ncloud server getServerProductList --serverImageProductCode SPSW0LINUX000130
variable "ncloud" {
  default = {
    region                    = "KR"
    site                      = "public"
    zone                      = "KR-1"
    server_image_product_code = "SPSW0LINUX000130"
    server_product_code       = "SPSVRSTAND000072"
  }
}

variable "ssh_external_port" {
  default = {
    cn_server  = "8022"
    cn_agent   = "8023"
    consul_mgw = "8024"
  }
}

variable "gcp_project" {}
variable "gcp_zone" {}
variable "gcp_server_ip" {}
// variable "gcp_mgw_ip" {}
variable "credentials_file" {}