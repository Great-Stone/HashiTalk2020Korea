job "count_dashboard" {
   datacenters = ["gcp"]
   type = "service"
   group "dashboard" {
     count = 1

     network {
      mode = "host"
     }
     
     task "dashboard" {
       driver = "docker"
       env {
         COUNTING_SERVICE_URL = "http://count-api.connect.ncloud.consul:9001"
       }
       config {
         image = "hashicorpnomad/counter-dashboard:v1"
         port_map = {
           http = 9002
         }
         network_mode = "host"
         ipc_mode = "host"
         dns_servers = [
           "127.0.0.1", "8.8.8.8"
         ]
         advertise_ipv6_address = false
       }

       service {
        name = "dashboard"
        tags = ["dashboard"]

        check {
          type  = "tcp"
          port  = "http"
          interval = "2s"
          timeout  = "2s"
          address_mode = "driver"
        }
      }

      resources {
        cpu    = 300
        memory = 256

        network {
          mbits = 100
          port "http" {
            static = 9002
          }
        }
      }
    }
  }
}
