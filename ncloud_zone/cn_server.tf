data "template_file" "cn_server" {
  template = file("${path.module}/templates/cn_server.sh")

  vars = {
    consul_version     = "1.8.2"
    consul_name        = "ncloud_server"
    datacenter         = "ncloud"
    region             = var.ncloud.region
    primary_datacenter = "gcp"
    credentials        = file(var.credentials_file)
    gcp_project        = var.gcp_project
    gcp_zone           = var.gcp_zone
    gcp_server_ip      = var.gcp_server_ip
  }
}

resource "ncloud_server" "cn_server" {
  name                      = "cn-server"
  server_image_product_code = var.ncloud.server_image_product_code
  server_product_code       = var.ncloud.server_product_code
  login_key_name            = ncloud_login_key.key.key_name
  zone                      = var.ncloud.zone
  user_data                 = data.template_file.cn_server.rendered

  tag_list {
    tag_key   = "owner"
    tag_value = "gs@hashicorp.com"
  }

}

data "ncloud_root_password" "cn_server_rootpwd" {
  server_instance_no = ncloud_server.cn_server.id
  private_key        = ncloud_login_key.key.private_key
}

// resource "ncloud_port_forwarding_rule" "cn_server_forwarding" {
//   //port_forwarding_configuration_no = data.ncloud_port_forwarding_rules.rules.id
//   server_instance_no            = ncloud_server.cn_server.id
//   port_forwarding_external_port = var.ssh_external_port.cn_server
//   port_forwarding_internal_port = "22"
// }

resource "ncloud_public_ip" "cn_server_public_ip" {
  server_instance_no = ncloud_server.cn_server.id
}

resource "null_resource" "cn_server_provisioner" {
  connection {
    type     = "ssh"
    host     = ncloud_public_ip.cn_server_public_ip.public_ip
    user     = "root"
    port     = "22"
    password = data.ncloud_root_password.cn_server_rootpwd.root_password
  }

  provisioner "remote-exec" {
    inline = [
      "export public_ip=${ncloud_public_ip.cn_server_public_ip.public_ip}",
      "sudo sed -i 's|PUBLIC_IP|'$public_ip'|g' /etc/systemd/system/consul.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl start consul",
      "sudo sed -i 's|PUBLIC_IP|'$public_ip'|g' /etc/nomad.d/server.hcl",
      "sudo systemctl daemon-reload",
      "sudo systemctl start nomad",
    ]
  }

  depends_on = [
    ncloud_public_ip.cn_server_public_ip,
  ]

  triggers = {
    always_run = timestamp()
  }
}

output "cn_server_pw" {
  value = "sshpass -p '${data.ncloud_root_password.cn_server_rootpwd.root_password}' ssh root@${ncloud_public_ip.cn_server_public_ip.public_ip} -oStrictHostKeyChecking=no"
}