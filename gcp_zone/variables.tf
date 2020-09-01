variable "gcp" {
  default = {
    project = "gs-test-282101"
    region  = "asia-northeast3"
    zone    = "asia-northeast3-a"
  }
}

variable "consul" {
  default = {
    server = "cn-server"
    agent  = "cn-agent"
    meshgw = "consul-mesh-gateway"
  }
}

variable "tag" {
  default = {
    mode  = "server"
    owner = "gs"
  }
}

variable "credentials" {
  default = ""
}

variable "credentials_file" {
}