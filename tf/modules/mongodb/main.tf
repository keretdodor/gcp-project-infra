# Creating the mondoDB's firewall rules

##############################################################
#             Creating the mondoDB's firewall rules
##############################################################


resource "google_compute_firewall" "bastion_ssh_firewall" {
  name    = "bastion-ssh-access"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.bastion_ip]  
  target_tags   = ["mongodb"]
}

resource "google_compute_firewall" "mongodb_firewall" {
  name    = "mongodb-internal-traffic"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_ranges = ["10.0.0.0/16"] 
  target_tags   = ["mongodb"]  
}

##############################################################
#               Creating the MongoDB insatnces
##############################################################

resource "google_compute_instance" "mongodb_instances" {
  count        = 3
  name         = "mongodb-${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
    }
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.private_subnet

    #Installing MongoDB and updating replicaset 

  }

   metadata = {
    ssh-keys = "keretdodorc:${file("/home/keretdodor/Desktop/gcp-project/mongo_key.pub")}"
    startup-script = <<-EOT
      #!/bin/bash
      
      sudo apt update
      sudo apt-get install gnupg curl
      curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
      sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
      --dearmor
      echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
      sudo apt-get install -y mongodb-org
      sudo systemctl start mongod


      echo 'replication:
        replSetName: "rsu"' | sudo tee -a /etc/mongod.conf
      
      sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

      sudo systemctl restart mongod
    EOT
  }

  tags = ["mongodb", "${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"]
    }

resource "null_resource" "initiate_replica_set" {

  provisioner "remote-exec" {
    inline = [

      "chmod 600 mongo_key.pem",
      "ssh -i mongo_key.pem keretdodorc@${google_compute_instance.mongodb_instances[0].network_interface[0].network_ip}", 
      "mongo --eval 'rs.initiate()'",
      "mongo --eval 'rs.add(\"${google_compute_instance.mongodb_instances[1].network_interface[0].network_ip}\")'",
      "mongo --eval 'rs.addArb(\"${google_compute_instance.mongodb_instances[2].network_interface[0].network_ip}\")'"
    ]

    connection {
      type        = "ssh"
      user        = "keretdodorc"
      private_key = file("/home/keretdodor/Desktop/gcp-project/bastion_host.pem")
      host        = var.bastion_ip
    }
  }
}
