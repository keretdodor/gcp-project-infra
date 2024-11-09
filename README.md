# WideOp's Terraform and GCP Peoject


Hey Amir and the rest of the team in WideOps
I created a highly available and fault tolerant MongoDB replica set and GKE cluster on sperate private subnets providing a secure and isolated environments all using terraform and gcp, and here is how i did it:

## Terraform Preparations

1. I created a **Cloud Storage** to store the .tfstate file securely and preventing it from being corrupted or destroyed with **Bucket Lock** and **Versioning** enabled
2. I created a Service Account with the **least privilege** principle allowing it to access and deploy only to the neccessary resources for this specific Terraform project, such as Compute Admin to deploy the MongoDB instances and the Bastion Host, Compute Netwrok Admin to deploy the VPC, private and public subnets and NAT Gateway. and Kubernetes Engine Admin and Kubernetes Engine Admin to create the GKE cluster, and also Storage Obejct Creator to create the new version of the tfstate file
3. I seperated each component of the project into modules
    #### Project Directory Structure:
    ```bash
    ├── k8s/                        
    │
    ├── tf/                         
    │   ├── main.tf                 
    │   ├── variables.tf            
    │   ├── locals.tf              
    │   ├── modules/
    │   │   ├── common/           
    │   │   │   ├── main.tf  # VPC, private and public subnets, NAT Gateway, Bastion Host       
    │   │   │   ├── variables.tf    
    │   │   │   ├── outputs.tf       
    │   │   │   └── data-sources.tf 
    │   │   ├── gke/                 
    │   │   │   ├── main.tf  # GKE Cluster         
    │   │   │   ├── variables.tf    
    │   │   │   ├── outputs.tf      
    │   │   │   └── data-sources.tf  
    │   │   ├── mongodb/             
    │   │   │   ├── main.tf  # MongoDB ReplicaSet   
    │   │   │   ├── variables.tf     
    │   │   │   ├── outputs.tf       
    │   │   │   └── data-sources.tf  
    │   │   │   ├── scripts/        
    │   │   │   │   ├── startup-mongo.sh  
    │   │   │   │   └── initiate-mongo.sh 

4. I understand that in production the setup would be different, I planned to create a landing zone that ensures each resource type (MongoDB, GKE, shared VPC) is housed within its own project, ensuring   resource isolation and fine-grained IAM control. This setup would involve creating four dedicated service accounts, each adhering to the least privilege principle for specific roles, and binding each account to the necessary project to enhance security and maintainability.
    
I understand that in production this is the procedure i would make

## The Networking Aspect - /modules/common

In this module, I created everything (almost) related to the Network:

### The VPC and Subnets

I created a vpc with the VPC resource, as well of three different subnets, **Two private subnets** for the GKE cluster and the MongoDB replicaset each. **One public subnet** for the Bastion Host for being able to SSH to the MongoDB replicaset and the GKE Nodes

each subnet had a different CIDR range to ensure there are no **overlapping ranges**. The MongoDB CIDR range is **10.0.0.0/24** , the GKE subnet has a **primary** CIDR range of **10.0.1.0/24** and two secondary CIDR ranges, one for the pods with a CIDR **10.0.2.0/25** and one for the services **10.0.2.128/25**. The public subnet has a CIDR range of **10.0.3.0/24**

### NAT Gateway

I created a NAT Gateway to ensure all the instances in the private subnets have access to outbound traffic, the NAT Gwateway was created with a **Cloud Router** as it acts as a traffic director and required to run a  NAT Gateway. i also attached the NAT Gateway with a **static IP** for future logging of whitelisting if necessary.


### Bastion Host

To connect to the replicaset and the GKE cluster that are in the private subnet i created a Bastion Host on the public subnet.

The Bastion Host a key pair stored locally that i set on the metadata as a familiar public key on the /.ssh/authorized_key file.

I also used **two provisioner** to transfer the private key of the MongoDB replicaset and the GKE nodes into the Bastion Host, the bastion host is open to port 22 and 80 with a dedicated **firewall rule**. 

*Identity-Aware Proxy (IAP) could be considered as a future alternative for more simplified, secure access.*

## The GKE Cluster - /modules/gke

### **`google_container_cluster`**:

The cluster is set to be highly available, the cluster will be deployed on two different zones configured with data sources. I added a fluentd pod for future logging and, i turned on the horizontal poding autoscaling option as it is not available by default. The control plane is set to the regular release version. 

### **`google_container_node_pool`**:

I created two node pools, one is **`general`**: containing two persistent nodes, on two different zones, ensuring reliablity and fault tolerant architecture.
Another node pool **`spot`**: with an auto scaling of 0 to 3, ensuring high availablity with lower cost and since there is already a persistent node pool, it is possible to execute.

All node pools configured with a key and a a firewall rule for the bastion host on port 22.

## The MongoDB Replica Set - /modules/mongodb

For the MongoDB replica set, i created two firewall rules, one is on port 22 for the bastion host privtate ip and another for the MongoDB itself on port 27017 accepting only traffic from inside the VPC on the range of 10.0.0.0/16

I created a **`google_compute_instance`** resource with a **`count=3`** (one primary, one secondary and one arbiter), each replica deployed on a different zone with the **`google_compute_zones`** data source. The instances deployed on a private subnet, with a unique key pair.

### **`startup-mongo.sh`**:

this script downloads MongoDB with the **`wget`** and command and **`apt`** . after MongoDB is downloaded on all 3 instances, the script echo the replica set's name to each instance making sure they are all under the same replica set with the **`tee -a`** , after that i use the **`sed -i`** command to replace the bindIp.

### resource  **`template_file`** and resource **`local_file`**:

Using the `join()` function, I created a template that generates the environment variable the Node app needs to connect to the MongoDB replica set as a single entity.

### resource **`null_resource`**

In this null resource, i created two provisioners. one to transer a local script to the Bastion Host and another one to remote exec it, here is how the script goes:

-  ### `initiate-mongo.sh`:

    Because the MongoDB cluster is in a private subnet we will need to SSH to it from the Bastion Host, I gave the right permissions to the MongoDB key and SSH to the one we set as primary before. to initiate the database, I firstly ran the `rs.initiate()` command.
    
    then set the RWConcern to 1 with w: "majority to allow balance performance and data consistency between the replica set.

    i then added the Secondary member to the replica set with the `rs.add()` command.

    While creating the script, i realized that i have a problem setting the primary insatnce as the host of the replica set so i reconfigured the replica set and after that added the Arbiter with the `rs.addArb()` command

At the end the MongoDB Replica Set should look like this:

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)