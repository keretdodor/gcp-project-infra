# gcp-project-infra


Hey Amir and the rest of the team in WideOps
I created a highly avaliable and fault tolerent MongoDB and GKE cluster on sperate private subnets providing a secure and isolated environments all using terraform and gcp, and here is how i did it:

## Terraform preperations:

1. I created a **Cloud Storage** to store the .tfstate file securely and preventing it from being corrupted or destroyed with **Bucket Lock** and **Versioning** enabled
2. I created a Service Account with the **least privilege** principle allowing it to access and deploy only to the neccessary resources for this specific Terraform project, such as Compute Admin to deploy the MongoDB instances and the Bastion Host, Compute Netwrok Admin to deploy the VPC, private and public subnets and NAT Gateway. and Kubernetes Engine Admin and Kubernetes Engine Admin to create the GKE cluster, and also Storage Obejct Creator to create the new virsion of the tfstate file
3. I wanted to create a landing zone with a Shared VPC and a seprate project to each group on resources but realized that i would need to create a Workspace account for the Organization ID that will cost me money so i didn't do that but i already planned how to do that:
    -   I would create three seprate projects for the MongoDB instances, one for the GKE cluster and Another for the shared VPC, NAT Gateway and the Bastion Host
    -   I would create four different Service accounts