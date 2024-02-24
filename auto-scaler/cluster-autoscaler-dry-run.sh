#!/bin/bash

export AWS_PROFILE=headsup-t3
export AWS_REGION=us-west-2

# Set the name of your EKS cluster
cluster_name="EKS-EWLEW39B"
# Replace with your AWS Account ID
AWS_ACCOUNT_ID="776885395346"
#edit image version 
v="v1.26.4"
# Get the OIDC provider ID
oidc_id=$(aws eks describe-cluster --name $cluster_name --profile $AWS_PROFILE --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

echo "oidec_id=$oidc_id"

# Check if an IAM OIDC provider with the cluster's ID already exists
provider_exists=$(aws iam list-open-id-connect-providers --profile $AWS_PROFILE | grep $oidc_id | cut -d "/" -f4)

# If no provider exists, create an IAM OIDC provider using eksctl
if [ -z "$provider_exists" ]; then
  echo "OIDC Provider is not exist, will create IAM OIDC provider for cluster: $cluster_name"
  #eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
else
  echo "IAM OIDC provider already exists for cluster: $cluster_name"
fi

if kubectl get serviceaccount cluster-autoscaler -n kube-system &> /dev/null; then
    echo "Service account cluster-autoscaler exists in namespace kube-system."
else
    echo "service account does not exist, will create service account  named as cluster-autoscaler and attache the below policy document in kube-system namespace
  ca-iam-policy.json:
	{
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
}
"
fi

# Download the cluster-autoscaler-autodiscover.yaml
curl -O https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit the cluster-autoscaler-autodiscover.yaml file
sed -i "s/<YOUR CLUSTER NAME>/$cluster_name/g" cluster-autoscaler-autodiscover.yaml

# Deploy the yaml file
kubectl apply -f cluster-autoscaler-autodiscover.yaml --dry-run=client
# Edit the Cluster Autoscaler deployment
# add two commands under container command
#--balance-similar-node-groups
#--skip-nodes-with-system-pods=false
echo " Edit the Cluster Autoscaler deployment"
echo " kubectl patch deployment cluster-autoscaler -n kube-system --type=json -p='[
    {"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--balance-similar-node-groups"},
    {"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--skip-nodes-with-system-pods=false"}
]' "




# Set the Cluster Autoscaler image tag
echo "Set the Cluster Autoscaler image tag"
echo "kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:$v "
kubectl get pods -n kube-system