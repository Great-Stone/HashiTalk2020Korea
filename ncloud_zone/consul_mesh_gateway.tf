// data "template_file" "consul_mgw" {
//   template = file("${path.module}/templates/consul_mgw.sh")
//   vars = {
//     consul_version     = "1.8.2"
//     consul_name        = "ncloud_mesh_gw"
//     datacenter         = "ncloud"
//     region             = var.ncloud.region
//     serverip           = ncloud_server.cn_server.private_ip
//     serverpw           = data.ncloud_root_password.cn_server_rootpwd.root_password
//     primary_datacenter = "gcp"
//     primary_mgw_ip     = var.gcp_mgw_ip
//   }
// }

// resource "ncloud_server" "consul_mgw" {
//   name                      = "consul-mesh-gateway"
//   server_image_product_code = var.ncloud.server_image_product_code
//   server_product_code       = var.ncloud.server_product_code
//   login_key_name            = ncloud_login_key.key.key_name
//   zone                      = var.ncloud.zone
//   user_data                 = data.template_file.consul_mgw.rendered

//   tag_list {
//     tag_key   = "owner"
//     tag_value = "gs@hashicorp.com"
//   }

//   depends_on = [
//     ncloud_server.cn_agent,
//   ]
// }

// data "ncloud_root_password" "consul_mgw_rootpwd" {
//   server_instance_no = ncloud_server.consul_mgw.id
//   private_key        = ncloud_login_key.key.private_key
// }

// // resource "ncloud_port_forwarding_rule" "consul_mgw_forwarding" {
// //   // port_forwarding_configuration_no = data.ncloud_port_forwarding_rules.rules.id
// //   server_instance_no            = ncloud_server.consul_mgw.id
// //   port_forwarding_external_port = var.ssh_external_port.consul_mgw
// //   port_forwarding_internal_port = "22"
// // }

// resource "ncloud_public_ip" "consul_mgw_public_ip" {
//   server_instance_no = ncloud_server.consul_mgw.id
// }

// resource "null_resource" "consul_mgw_provisioner" {
//   connection {
//     type     = "ssh"
//     host     = ncloud_public_ip.consul_mgw_public_ip.public_ip
//     user     = "root"
//     port     = "22"
//     password = data.ncloud_root_password.consul_mgw_rootpwd.root_password
//   }

//   provisioner "remote-exec" {
//     inline = [
//       "export private_ip=${ncloud_server.consul_mgw.private_ip}",
//       "export public_ip=${ncloud_public_ip.consul_mgw_public_ip.public_ip}",
//       "sudo sed -i 's|PUBLIC_IP|'$public_ip'|g' /etc/systemd/system/consul.service",
//       "sudo systemctl daemon-reload",
//       "sudo systemctl start consul",
//       "sleep 5",
//       "sudo consul connect envoy -expose-servers -mesh-gateway -register -service 'gateway-primary' -address $private_ip:8080 -wan-address $public_ip:8080 -admin-bind 127.0.0.1:19005 &",
//     ]
//   }

//   depends_on = [
//     ncloud_public_ip.consul_mgw_public_ip,
//     ncloud_server.consul_mgw
//   ]
// }

// output "consul_start_mesh_gateway" {
//   value = "consul connect envoy -mesh-gateway -register -service 'gateway-primary' -address ${ncloud_server.consul_mgw.private_ip}:8080 -wan-address ${ncloud_public_ip.consul_mgw_public_ip.public_ip}:8080 -admin-bind 127.0.0.1:19005 -token=$CONSUL_MESH_TOKEN"
// }

// output "consul_mgw_pw" {
//   value = "sshpass -p '${data.ncloud_root_password.consul_mgw_rootpwd.root_password}' ssh root@${ncloud_public_ip.consul_mgw_public_ip.public_ip} -oStrictHostKeyChecking=no"
// }