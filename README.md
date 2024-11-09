# WideOp's Terraform and GCP Peoject


Hey Amir and the rest of the team in WideOps
I created a highly avaliable and fault tolerent MongoDB replica set and GKE cluster on sperate private subnets providing a secure and isolated environments all using terraform and gcp, and here is how i did it:

## Terraform Preperations

1. I created a **Cloud Storage** to store the .tfstate file securely and preventing it from being corrupted or destroyed with **Bucket Lock** and **Versioning** enabled
2. I created a Service Account with the **least privilege** principle allowing it to access and deploy only to the neccessary resources for this specific Terraform project, such as Compute Admin to deploy the MongoDB instances and the Bastion Host, Compute Netwrok Admin to deploy the VPC, private and public subnets and NAT Gateway. and Kubernetes Engine Admin and Kubernetes Engine Admin to create the GKE cluster, and also Storage Obejct Creator to create the new virsion of the tfstate file
3. I seprated each component of the project into modules
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

4. I wanted to create a landing zone with a Shared VPC and a seprate project to each group on resources but realized that i would need to create a Workspace account for the Organization ID that will cost me money so i didn't do that but i already planned how to do that:
    -   I would create three seprate projects for the MongoDB instances, one for the GKE cluster and Another for the shared VPC, NAT Gateway and the Bastion Host
    -   I would create four different Service accounts one for Terraform, one for the MongoDB project, one for the GKE project and another for the Shared VPC project each having their own iam roles guided with **least privilege** principle
    -   After that to combine set each project to it's Service Account i would create IAM binding for each Service Account

## modules/common

In this module, I created everything (almost) related to the Network:

### The VPC and Subnets

I cerated a vpc with the VPC resource, as well of three different subnets, **Two private subnets** for the GKE cluster and the MongoDB replicaset each. **One public subnet*** for the Bastion Host for being able to SSH to the MongoDB replicaset and the GKE Nodes

each subnet had a different CIDR range to ensure there are no **overlapsing ranges**. The MongoDB CIDR range is **10.0.0.0/24** , the GKE subnet has a **primary** CIDR range of **10.0.1.0/24** and two secondary CIDR ranges, one for the pods with a CIDR **10.0.2.0/25** and one for the services **10.0.2.128/25**. The public subnet has a CIDR range of **10.0.3.0/24**

### NAT Gateway

