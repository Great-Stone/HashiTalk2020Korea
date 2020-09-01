job "count_api" {
   datacenters = ["ncloud"]
   group "api" {
     task "api" {
       driver = "docker"
       config {
         image = "hashicorpnomad/counter-api:v2"
       }
       resources {
         network {
          port "http" {
            static = "9001"
            to = "9001"
            host_network = "public"
          }
        }
       }
     }
   }
 }

 job "count_api" {
   datacenters = ["ncloud"]
   group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }

      check {
        expose   = true
        name     = "api-health"
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v2"
      }
    }
  }
}