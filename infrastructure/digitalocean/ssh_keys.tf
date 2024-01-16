resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "digitalocean_ssh_key" "default" {
  name       = "Wireguard Terraform SSH Key"
  public_key = tls_private_key.ssh.public_key_openssh
}
