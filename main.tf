terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}


provider digitalocean {
  token = "DIGITALOCEAN" 
}


resource digitalocean_ssh_key default {
  name       = "JenkinsKey"
  public_key = file("public_key.pub")
}


resource digitalocean_droplet jenkins {
  image  = "docker-20-04"  
  name   = "jenkins"
  region = "nyc1"
  size   = "s-1vcpu-1gb"  
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}


resource tls_private_key key {
  algorithm = "RSA"
}


resource tls_self_signed_cert cert {
  private_key_pem = tls_private_key.key.private_key_pem

  validity_period_hours = 8760  

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}


resource null_resource install_docker {
  triggers = {
    droplet_id = digitalocean_droplet.jenkins.id
  }

  provisioner remote-exec {
    connection {
      type        = "ssh"
      user        = "root" 
      private_key = file("public_key.pem")
      host        = digitalocean_droplet.jenkins.ipv4_address
    }

    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y git default-jdk",
      "sudo wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo apt-key add -",
      "echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y jenkins",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      
    ]
  }
}