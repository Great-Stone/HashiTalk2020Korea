terraform {
  required_version = ">= 0.13"
  // backend "remote" {
  //   hostname = "app.terraform.io"
  //   organization = "great-stone-biz"

  //   workspaces {
  //     name = "hashitalk2020"
  //   }
  // }
}

// primary
module "GCP_zone" {
  source = "./gcp_zone"

  credentials_file = "./gs-test-89fe78a06737.json"
}

// secondary
module "NCloud_zone" {
  source = "./ncloud_zone"

  gcp_project      = "gs-test-282101"
  gcp_zone         = "asia-northeast3-a"
  gcp_server_ip    = module.GCP_zone.server_public_ip
  // gcp_mgw_ip       = module.GCP_zone.mgw_public_ip
  credentials_file = "./gs-test-89fe78a06737.json"
}

output "ncloud" {
  value = {
    "02_cn_agent_pw"               = module.NCloud_zone.cn_agent_pw
    "01_cn_server_pw"              = module.NCloud_zone.cn_server_pw
  }
}

output "server_ip" {
  value = {
    "public_ip"  = module.GCP_zone.server_public_ip
    "private_ip" = module.GCP_zone.server_private_ip
  }
}