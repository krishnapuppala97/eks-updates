 # EKS Cluster Autoscaler Setup

Automate the Cluster Autoscaler setup for AWS EKS using a shell script. This script manages AWS resources and deploys the Cluster Autoscaler on EKS.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
- [Behind the Script](#behind-the-script)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Monitoring](#monitoring)

## Prerequisites

- **AWS CLI**: Make sure it's installed and configured with the necessary permissions.
- **kubectl**: Ensure it's installed and set up for the EKS cluster you want to work on.
- **eksctl**: This is required for creating certain AWS resources.
- An existing EKS cluster where the Cluster Autoscaler will be set up.

## Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/intraedge-services/ms-headsup.git  
2. Navigate to the repository's directory:
   ```bash
   cd ms-headsup/iac/cluseter-autoscaler
3. Make the script executable:
    ```bash
     chmod +x setup-cluster-autoscaler.sh
    
## Usage
1. Open the shell script `setup-cluster-autoscaler.sh` in an editor.
2. Replace `<AWS_PROFILE>` with the name of your AWS PROFILE name.
3. Replace `<AWS_REGION>` with your cluster Region.
4. Replace `<Enter Cluster Name>` with the name of your EKS cluster.
5. Replace `<Enter your AWS Account ID>` with your AWS Account ID.
6. Update the `v` variable with the cluster autoscaler image tag
7. Save and close the file
8. Run the script:
   ```bash
   ./setup-cluster-autoscaler.sh
## Behind the Script:
1. ***IAM OIDC Provider***: Checks if an OIDC provider for the EKS cluster exists. If not, it creates one.
2. ***IAM Policy***: Generates an IAM policy JSON for the Cluster Autoscaler and then creates the policy in AWS.
3. ***IAM Service Account***: Uses `eksctl` to create an IAM service account with the necessary permissions for the Cluster Autoscaler.
4. ***Cluster Autoscaler Deployment***:  Downloads the necessary YAML file for the Cluster Autoscaler, edits it with your cluster name, and deploys it using `kubectl`.
5. ***Modifications***:Tweaks the Cluster Autoscaler deployment with additional parameters to balance similar node groups and to consider nodes with system pods for scaling actions.
6. ***Update Cluster Autoscaler Image***:Sets the image of the Cluster Autoscaler deployment to the desired version.

## Clean Up:
The script leaves a couple of commented out rm commands at the end. If you want the script to automatically delete the temporary files it creates (`ca-iam-policy.json` and `cluster-autoscaler-autodiscover.yaml`), you can uncomment these lines.

## Troubleshooting:
- Check the Cluster Autoscaler logs.
- Ensure that IAM roles and policies are correctly set up.
- Verify that the service account was created and has the correct permissions.


## Monitoring:
- After setup, you can view the Cluster    Autoscaler   logs with the following command:
```bash  
  kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler

