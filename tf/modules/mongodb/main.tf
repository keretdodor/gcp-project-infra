resource "google_compute_firewall" "bastion_ssh_firewall" {
  name    = "bastion-ssh-access"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.bastion_ip]  
  target_tags   = ["mongo"]
}

resource "google_compute_firewall" "mongodb_firewall" {
  name    = "mongodb-internal-traffic"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_ranges = ["10.0.0.0/16"] 
  target_tags   = ["mongo"]  
}

resource "google_compute_instance" "mongodb_instances" {
  count        = 3
  name         = "mongodb-${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.private_subnet_name

    #Installing MongoDB and changing artibutes for each 
  metadata_startup_script = <<-EOT
    #!/bin/bash
 
    sudo apt update
    sudo apt install -y mongodb
    
    # Setup MongoDB config based on instance role
    if [[ "${count.index}" -eq 0 ]]; then
      echo 'replication:
        replSetName: "rsu"' | sudo tee -a /etc/mongod.conf
      sudo systemctl restart mongod
    elif [[ "${count.index}" -eq 1 ]]; then
      echo 'replication:
        replSetName: "rsu"' | sudo tee -a /etc/mongod.conf
      sudo systemctl restart mongod
    else

      echo 'replication:
        replSetName: "rsu"' | sudo tee -a /etc/mongod.conf
      sudo systemctl restart mongod
    fi
  EOT

  tags = ["mongodb", "${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"]
    }
}


resource "null_resource" "initiate_replica_set" {
  provisioner "remote-exec" {
    inline = [
      "mongo --eval 'rs.initiate()'",
      "mongo --eval 'rs.add(\"secondary_private_ip\")'",
      "mongo --eval 'rs.addArb(\"arbiter_private_ip\")'"
    ]

    connection {
      type        = "ssh"
      user        = "username"
      private_key = file("path_to_your_private_key")
      host        = google_compute_instance.mongodb_instances[0].network_interface.0.network_ip
    }
  }
}
