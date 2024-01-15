locals {
  ssh_pub_key  = file("~/.ssh/id_ed25519.pub")
  ssh_priv_key = file("~/.ssh/id_ed25519")

  nonroot_user_name = "terraform_user"

  wg_cidr_range    = "10.180.200.1/24"
  wg_cidr_prefix   = trimsuffix(local.wg_cidr_range, ".1/24")
  wg_cidr_start_ip = 2
  wg_port          = "51820"

  num_clients    = 1
  client_cfg_dir = "/root/client-cfg"

  ALLOW_SSH_ACCESS = false
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "= 2.34.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.2"
    }
  }
}

provider "digitalocean" {}

provider "random" {}
