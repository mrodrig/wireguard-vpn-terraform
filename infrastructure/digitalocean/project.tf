resource "digitalocean_project" "main" {
  name        = "Wireguard"
  description = "A project to represent travel Wireguard VPN resources."
  purpose     = "Service or API"
  environment = "Production"
  resources = [
    digitalocean_droplet.server.urn,
  ]
}
