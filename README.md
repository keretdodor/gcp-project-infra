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

The cluster is set to be highly available, it will be deployed on two different zones configured with data sources. I added a fluentd pod for future logging and, i turned on the horizontal poding autoscaling option as it is not available by default. The control plane is set to the regular release version. 

### **`google_container_node_pool`**

I created two node pools