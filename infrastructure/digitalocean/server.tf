resource "digitalocean_ssh_key" "default" {
  name       = "Development SSH Key"
  public_key = local.ssh_pub_key
}

resource "digitalocean_droplet" "server" {
  name          = "wg-server"
  image         = "ubuntu-22-04-x64"
  region        = "nyc1"
  size          = "s-1vcpu-512mb-10gb"
  droplet_agent = true
  ssh_keys = [
    digitalocean_ssh_key.default.fingerprint
  ]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_priv_key
    host        = self.ipv4_address
  }

  # https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-22-04
  # https://www.cyberciti.biz/tips/howto-write-shell-script-to-add-user.html

  provisioner "remote-exec" {
    inline = [
      # Update Droplet console
      # "wget -qO- https://repos-droplet.digitalocean.com/install.sh | sudo bash",

      # Use non-interactive installs to not hang the provisioning process
      "sudo apt update",
      "sleep 1", # sleep to allow apt to unlock properly
      "sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt upgrade -y",
      # "DEBIAN_FRONTEND=noninteractive sudo apt-get install --no-install-recommends -y xz-utils git wget curl",

      # # Add non-root user account
      # "NR_USER_PASS=${random_password.nonroot_user_password}",
      # "SALTED_PASS=$(perl -e 'print crypt($ARGV[0], \"password\")' $NR_USER_PASS)",
      # "useradd -m -p $SALTED_PASS ${local.nonroot_user_name}",
      # "usermod -aG sudo ${local.nonroot_user_name}",

      # Enable ufw firewall - denies all by default
      "sudo ufw app list",
      "sudo ufw allow OpenSSH",
      "sudo ufw allow 51820/udp",
      "sudo ufw --force enable",
      "sudo ufw status",

      # Install Wireguard
      "sudo apt update",
      "sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt install wireguard -y",

      # Configure Wireguard
      "wg genkey | sudo tee /etc/wireguard/private.key",                                      # Generate private key file
      "sudo chmod go= /etc/wireguard/private.key",                                            # Removes all non-root permissions to the file
      "sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key", # Generate public key file
      "touch /etc/wireguard/wg0.conf",
      "echo [Interface] > /etc/wireguard/wg0.conf",
      "echo PrivateKey = $(sudo cat /etc/wireguard/private.key) >> /etc/wireguard/wg0.conf",
      "echo Address = ${local.wg_cidr_range} >> /etc/wireguard/wg0.conf",
      "echo ListenPort = ${local.wg_port} >> /etc/wireguard/wg0.conf",
      "echo SaveConfig = true >> /etc/wireguard/wg0.conf",

      "sudo echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf",
      "sudo echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf", # only needed for ipv6
      "sudo sysctl -p",

      "export DEFAULT_INTF=$(ip route list default | grep 'default' | awk -F ' ' '{ print $5}')",
      "echo PostUp = ufw route allow in on wg0 out on $DEFAULT_INTF >> /etc/wireguard/wg0.conf",
      "echo PostUp = iptables -t nat -I POSTROUTING -o $DEFAULT_INTF -j MASQUERADE >> /etc/wireguard/wg0.conf",
      "echo PostUp = ip6tables -t nat -I POSTROUTING -o $DEFAULT_INTF -j MASQUERADE >> /etc/wireguard/wg0.conf",
      "echo PreDown = ufw route delete allow in on wg0 out on $DEFAULT_INTF >> /etc/wireguard/wg0.conf",
      "echo PreDown = iptables -t nat -D POSTROUTING -o $DEFAULT_INTF -j MASQUERADE >> /etc/wireguard/wg0.conf",
      "echo PreDown = ip6tables -t nat -D POSTROUTING -o $DEFAULT_INTF -j MASQUERADE >> /etc/wireguard/wg0.conf",

      "sudo systemctl enable wg-quick@wg0.service",
      "sudo systemctl start wg-quick@wg0.service",
      # "sudo systemctl status wg-quick@wg0.service", # seems to hang the provisioner

      # Generate peer configuration keys and config file
      "export DNS_SERVERS=$(resolvectl dns eth0 | awk -F'): ' '{ print $2 }' | awk -F' ' '{for (i=1; i<=NF; i++) printf(\"%s, \",$i); print \"\"}')",
      "export FORMATTED_DNS_SERVERS=$(echo $DNS_SERVERS | sed 's/,$//')",
      "mkdir ~/client-cfg",
      "wg genkey | sudo tee ${local.client_cfg_dir}/private.key",
      "sudo chmod go= ${local.client_cfg_dir}/private*.key",
      "sudo cat ${local.client_cfg_dir}/private.key | wg pubkey | sudo tee ${local.client_cfg_dir}/public.key",
      "echo [Interface] > ${local.client_cfg_dir}/client.conf",
      "echo PrivateKey = $(sudo cat ${local.client_cfg_dir}/private.key) >> ${local.client_cfg_dir}/client.conf",
      "echo Address = ${local.wg_cidr_prefix}.${local.wg_cidr_start_ip}/32 >> ${local.client_cfg_dir}/client.conf",
      "echo DNS = $DNS_SERVERS >> ${local.client_cfg_dir}/client.conf",
      "echo >> ${local.client_cfg_dir}/client.conf",
      "echo [Peer] >> ${local.client_cfg_dir}/client.conf",
      "echo PublicKey = $(sudo cat /etc/wireguard/public.key) >> ${local.client_cfg_dir}/client.conf",
      "echo Endpoint = ${self.ipv4_address}:${local.wg_port} >> ${local.client_cfg_dir}/client.conf",
      "echo AllowedIPs = 0.0.0.0/0 >> ${local.client_cfg_dir}/client.conf", # send all traffic over the VPN

      # Add peer to Wireguard server config
      "sudo wg set wg0 peer $(sudo cat ${local.client_cfg_dir}/public.key) allowed-ips ${local.wg_cidr_prefix}.${local.wg_cidr_start_ip}",
      "sudo wg",
    ]
  }
}

data "remote_file" "config" {
  conn {
    user        = "root"
    private_key = local.ssh_priv_key
    host        = digitalocean_droplet.server.ipv4_address
    sudo        = true
  }

  path = "${local.client_cfg_dir}/client.conf"
}

output "client-cfg" {
  value = data.remote_file.config.content
}

