service {
  name = "count-api"
  tags = ["api"]
  port = 9001

  connect {
    native = true
  }

  check {
    id    = "api-health"
    name  = "Count API Health Check"
    http  = "http://10.34.101.113:9001/health"
    method = "GET"
    interval = "2s"
    timeout  = "2s"
  }

  tagged_addresses {
      lan {
        address = "10.34.101.113",
        port = 9001,
      },
      wan {
        address = "61.97.191.71",
        port = 9001
      }
    },
}