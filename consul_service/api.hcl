service {
  name = "count-api"
  tags = ["api"]
  port = 9001

  connect {
    native = true
  }

  tagged_addresses {
      lan {
        address = "10.34.100.136",
        port = 9001,
      },
      wan {
        address = "61.97.191.46",
        port = 9001
      }
    },
}