resource "digitalocean_firewall" "main" {
  name = "wg-firewall"

  droplet_ids = [
    digitalocean_droplet.server.id
  ]

  # the following rule is only needed if we need to manually connect to the droplet via the DO web console
  dynamic "inbound_rule" {
    # If SSH access is allowed, then the inbound_rule block will be run once, otherwise it will not be executed meaning that no rule allowing SSH access will be added to the firewall resource
    for_each = local.ALLOW_SSH_ACCESS ? [1] : []

    content {
      protocol         = "tcp"
      port_range       = "22" # ssh
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = local.wg_port
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    destination_droplet_ids        = []
    destination_kubernetes_ids     = []
    destination_load_balancer_uids = []
    destination_tags               = []
    port_range                     = "all"
    protocol                       = "tcp"
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    destination_droplet_ids        = []
    destination_kubernetes_ids     = []
    destination_load_balancer_uids = []
    destination_tags               = []
    port_range                     = "all"
    protocol                       = "udp"
  }

  outbound_rule {
    destination_addresses = [
      "0.0.0.0/0",
      "::/0",
    ]
    destination_droplet_ids        = []
    destination_kubernetes_ids     = []
    destination_load_balancer_uids = []
    destination_tags               = []
    protocol                       = "icmp"
  }
}
