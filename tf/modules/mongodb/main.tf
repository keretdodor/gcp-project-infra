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

  source_ranges = [var.bastion_prv_ip]  
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
    install gnupg2 wget
    wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
    
    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    
    sudo apt update
    sudo apt-get install -y mongodb-org
    
    sudo systemctl start mongod
    sudo systemctl enable mongod
    sudo systemctl status mongod
    
    sudo systemctl stop mongod
    
    echo 'replication:
       replSetName: "rsu"' | sudo tee -a /etc/mongod.conf
     
    sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

    sudo systemctl restart mongod

    EOT
  }

  tags = ["mongodb", "${count.index == 0 ? "primary" : count.index == 1 ? "secondary" : "arbiter"}"]

  depends_on = [var.nat_router_id]

    }

resource "template_file" "env_file" {
  template = <<-EOT
    mongodb://${join(":27017,", google_compute_instance.mongodb_instances[*].network_interface[0].network_ip)}:27017/mydb?replicaSet=rsu
  EOT
}

resource "local_file" "app_env" {
  content  = template_file.env_file.rendered
  filename = "/home/keretdodor/Desktop/gcp-project/configmapenv.txt"
}

resource "null_resource" "initiate_replica_set" {

  provisioner "file" {
      source      = "/home/keretdodor/Desktop/gcp-project/gcp-project-infra/tf/modules/mongodb/initiate-mongo.sh"
      destination = "/tmp/initiate-mongo.sh"

  connection {
      type        = "ssh"
      user        = "keretdodorc"
      agent       = "false"
      port        = 22
      private_key = file("/home/keretdodor/Desktop/gcp-project/bastion_host.pem")
      host        = var.bastion_pub_ip
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "keretdodorc"
      agent       = "false"
      port        = 22
      private_key = file("/home/keretdodor/Desktop/gcp-project/bastion_host.pem")
      host        = var.bastion_pub_ip
    }
   
    inline = [

      "chmod +x /tmp/initiate-mongo.sh",
      "/tmp/initiate-mongo.sh ${google_compute_instance.mongodb_instances[0].network_interface[0].network_ip} ${google_compute_instance.mongodb_instances[1].network_interface[0].network_ip} ${google_compute_instance.mongodb_instances[2].network_interface[0].network_ip}",

    ]

  }

  depends_on = [google_compute_instance.mongodb_instances, google_compute_firewall.bastion_ssh_firewall]

  }
