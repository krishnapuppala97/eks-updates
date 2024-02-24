#!/bin/bash

export AWS_PROFILE=headsup-admin
export AWS_REGION=us-west-2

# Set the name of your EKS cluster
cluster_name="EKS-EWLEW39B"
# Replace with your AWS Account ID
AWS_ACCOUNT_ID="776885395346"
#edit image version 
v="v1.26.4"
# Get the OIDC provider ID
oidc_id=$(aws eks describe-cluster --name $cluster_name --profile $AWS_PROFILE --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

# Check if an IAM OIDC provider with the cluster's ID already exists
provider_exists=$(aws iam list-open-id-connect-providers --profile $AWS_PROFILE | grep $oidc_id | cut -d "/" -f4)

# If no provider exists, create an IAM OIDC provider using eksctl
if [ -z "$provider_exists" ]; then
  echo "Creating IAM OIDC provider for cluster: $cluster_name"
  eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
else
  echo "IAM OIDC provider already exists for cluster: $cluster_name"
fi

# Create a file for the policy document
echo '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}' > ca-iam-policy.json

# Create the IAM policy
policy_arn=$(aws iam create-policy --profile $AWS_PROFILE \
  --policy-name k8s-cluster-autoscaler-asg-policy \
  --policy-document file://ca-iam-policy.json \
  --query 'Policy.Arn' --output text)

echo "Created IAM policy: $policy_arn"

# Create an IAM role for the cluster-autoscaler Service Account
eksctl create iamserviceaccount \
    --name cluster-autoscaler \
    --namespace kube-system \
    --cluster $cluster_name \
    --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/k8s-cluster-autoscaler-asg-policy" \
    --approve \
    --override-existing-serviceaccounts

# Clean up - remove the temporary policy document file
#rm ca-iam-policy.json

# Download the cluster-autoscaler-autodiscover.yaml
curl -O https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit the cluster-autoscaler-autodiscover.yaml file
sed -i "s/<YOUR CLUSTER NAME>/$cluster_name/g" cluster-autoscaler-autodiscover.yaml

# Deploy the yaml file
kubectl apply -f cluster-autoscaler-autodiscover.yaml

# Edit the Cluster Autoscaler deployment
# add two commands under container command
#--balance-similar-node-groups
#--skip-nodes-with-system-pods=false
kubectl patch deployment cluster-autoscaler -n kube-system --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--balance-similar-node-groups"}, {"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--skip-nodes-with-system-pods=false"}]'



# Set the Cluster Autoscaler image tag
kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:$v

# Clean up - remove the temporary yaml file
#rm cluster-autoscaler-autodiscover.yaml

kubectl get pods -n kube-system
#View your Cluster Autoscaler logs with the following command.
#kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler