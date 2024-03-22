# You could Run this notebook using extension
# Shell Runner Notebooks tylerleonhardt.shell-runner-notebooks
# REFERENCE to OFFICIAL TAP 1.8 on AWS Installation step by step guide
# https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.8/tap/install-aws-intro.html
# https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.8/cluster-essentials/deploy.html
# Tanzu CLI and AWS cli shall be installed and configure with proper credentials
# 
# CREATE AWS RESOURCES and set AWS environment Variables Account ID Default Region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export AWS_REGION=$(aws configure list | grep region | awk '{print $2}')
aws sts get-caller-identity --query "Account" --output text
# EKS_CLUSTER_NAME Require user input - Create a distinct name 
# Optional to use yml definition file 
# #eksctl create cluster -f tanzu-tap/Notebooks/eks-cluster.yml  
export EKS_CLUSTER_NAME=YOUR_CLUSTER
eksctl create cluster --name $EKS_CLUSTER_NAME --managed --region $AWS_REGION --spot --instance-types t3.xlarge --version 1.29 --with-oidc -N 5
# ECR repo creation for TAP and Build Service
aws ecr create-repository --repository-name tap-images --region $AWS_REGION
aws ecr create-repository --repository-name tap-build-service --region $AWS_REGION
aws ecr create-repository --repository-name tbs-full-deps --region $AWS_REGION
aws ecr create-repository --repository-name tap-lsp --region $AWS_REGION
aws ecr create-repository --repository-name tanzu-cluster-essentials --region $AWS_REGION
# ECR repo creation for workload 
aws ecr create-repository --repository-name tanzu-application-platform/tanzu-java-web-app-dev-ns --region $AWS_REGION
aws ecr create-repository --repository-name tanzu-application-platform/tanzu-java-web-app-dev-ns-bundle --region $AWS_REGION
# Retrieve the OIDC endpoint from the Kubernetes cluster and store it for use in the policy.
export OIDCPROVIDER=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --output json | jq '.cluster.identity.oidc.issuer' | tr -d '"' | sed 's/https:\/\///')

cat << EOF > build-service-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDCPROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${OIDCPROVIDER}:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "${OIDCPROVIDER}:sub": [
                        "system:serviceaccount:kpack:controller",
                        "system:serviceaccount:build-service:dependency-updater-controller-serviceaccount"
                    ]
                }
            }
        }
    ]
}
EOF
cat << EOF > build-service-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:DescribeRegistry",
                "ecr:GetAuthorizationToken",
                "ecr:GetRegistryPolicy",
                "ecr:PutRegistryPolicy",
                "ecr:PutReplicationConfiguration",
                "ecr:DeleteRegistryPolicy"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "TAPEcrBuildServiceGlobal"
        },
        {
            "Action": [
                "ecr:DescribeImages",
                "ecr:ListImages",
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:BatchGetRepositoryScanningConfiguration",
                "ecr:DescribeImageReplicationStatus",
                "ecr:DescribeImageScanFindings",
                "ecr:DescribeRepositories",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetRegistryScanningConfiguration",
                "ecr:GetRepositoryPolicy",
                "ecr:ListTagsForResource",
                "ecr:TagResource",
                "ecr:UntagResource",
                "ecr:BatchDeleteImage",
                "ecr:BatchImportUpstreamImage",
                "ecr:CompleteLayerUpload",
                "ecr:CreatePullThroughCacheRule",
                "ecr:CreateRepository",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeletePullThroughCacheRule",
                "ecr:DeleteRepository",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:PutImageScanningConfiguration",
                "ecr:PutImageTagMutability",
                "ecr:PutLifecyclePolicy",
                "ecr:PutRegistryScanningConfiguration",
                "ecr:ReplicateImage",
                "ecr:StartImageScan",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:UploadLayerPart",
                "ecr:DeleteRepositoryPolicy",
                "ecr:SetRepositoryPolicy"
            ],
            "Resource": [
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/full-deps",
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/tap-build-service",
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/tap-images"
            ],
            "Effect": "Allow",
            "Sid": "TAPEcrBuildServiceScoped"
        }
    ]
}
EOF
cat << EOF > workload-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:DescribeRegistry",
                "ecr:GetAuthorizationToken",
                "ecr:GetRegistryPolicy",
                "ecr:PutRegistryPolicy",
                "ecr:PutReplicationConfiguration",
                "ecr:DeleteRegistryPolicy"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "TAPEcrWorkloadGlobal"
        },
        {
            "Action": [
                "ecr:DescribeImages",
                "ecr:ListImages",
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:BatchGetRepositoryScanningConfiguration",
                "ecr:DescribeImageReplicationStatus",
                "ecr:DescribeImageScanFindings",
                "ecr:DescribeRepositories",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetRegistryScanningConfiguration",
                "ecr:GetRepositoryPolicy",
                "ecr:ListTagsForResource",
                "ecr:TagResource",
                "ecr:UntagResource",
                "ecr:BatchDeleteImage",
                "ecr:BatchImportUpstreamImage",
                "ecr:CompleteLayerUpload",
                "ecr:CreatePullThroughCacheRule",
                "ecr:CreateRepository",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeletePullThroughCacheRule",
                "ecr:DeleteRepository",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:PutImageScanningConfiguration",
                "ecr:PutImageTagMutability",
                "ecr:PutLifecyclePolicy",
                "ecr:PutRegistryScanningConfiguration",
                "ecr:ReplicateImage",
                "ecr:StartImageScan",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:UploadLayerPart",
                "ecr:DeleteRepositoryPolicy",
                "ecr:SetRepositoryPolicy"
            ],
            "Resource": [
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/full-deps",
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/tanzu-application-platform/*"
            ],
            "Effect": "Allow",
            "Sid": "TAPEcrWorkloadScoped"
        }
    ]
}
EOF
cat << EOF > workload-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDCPROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "${OIDCPROVIDER}:sub": "system:serviceaccount:*:default",
                    "${OIDCPROVIDER}:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF


cat << EOF > local-source-proxy-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDCPROVIDER}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${OIDCPROVIDER}:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "${OIDCPROVIDER}:sub": [
                        "system:serviceaccount:tap-local-source-system:proxy-manager"
                    ]
                }
            }
        }
    ]
}
EOF


cat << EOF > local-source-proxy-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "TAPLSPGlobal"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": [
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/tap-lsp"
            ],
            "Sid": "TAPLSPScoped"
        }
    ]
}
EOF
# Create the Tanzu Build Service Role.
aws iam create-role --role-name tap-build-service --assume-role-policy-document file://build-service-trust-policy.json
# Attach the Policy to the Build Role.
aws iam put-role-policy --role-name tap-build-service --policy-name tapBuildServicePolicy --policy-document file://build-service-policy.json

# Create the Workload Role.
aws iam create-role --role-name tap-workload --assume-role-policy-document file://workload-trust-policy.json
# Attach the Policy to the Workload Role.
aws iam put-role-policy --role-name tap-workload --policy-name tapWorkload --policy-document file://workload-policy.json

# Create the TAP Local Source Proxy Role.
aws iam create-role --role-name tap-local-source-proxy --assume-role-policy-document file://local-source-proxy-trust-policy.json
# Attach the Policy to the tap-local-source-proxy Role created earlier.
aws iam put-role-policy --role-name tap-local-source-proxy --policy-name tapLocalSourcePolicy --policy-document file://local-source-proxy-policy.json
# Check created role and policy binding
aws iam get-role --role-name tap-build-service --output text
aws iam get-role-policy --role-name tap-build-service --policy-name tapBuildServicePolicy --output text
aws iam get-role --role-name tap-workload --output text
aws iam get-role-policy --role-name tap-workload --policy-name tapWorkload --output text
# End of Create AWS Resources Page
# Relocate Images to a registry
# Parameter setup - Repeat some of them just in case you restart from this session.
# Get AWS Account ID and Region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text) 
export AWS_REGION=$(aws configure list | grep region | awk '{print $2}')
# Download tanzu cluster essentials - Browser or Pivnet
pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.8.0' --product-file-id=1720348
mkdir tanzu-cluster-essentials-1.8
tar -xvf tanzu-cluster-essentials-darwin-amd64-1.8.0.tgz -C tanzu-cluster-essentials-1.8
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:8b4c5b575a015c7490b67329b14e9ca160753b047ba411e937af0f6d317e1596
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=yourusername@domain.com
export INSTALL_REGISTRY_PASSWORD='password'
./install.sh --yes
# Set tanzunet as the source registry to copy the Tanzu Application Platform packages from.
export IMGPKG_REGISTRY_HOSTNAME_0=registry.tanzu.vmware.com
export IMGPKG_REGISTRY_USERNAME_0=yourusername@domain.com
export IMGPKG_REGISTRY_PASSWORD_0='password'
# User regional ECR registry
export IMGPKG_REGISTRY_HOSTNAME_1=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export IMGPKG_REGISTRY_USERNAME_1=AWS
export IMGPKG_REGISTRY_PASSWORD_1=`aws ecr get-login-password --region $AWS_REGION`
# ENV variables for imgpkg command only
export INSTALL_REGISTRY_HOSTNAME=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export INSTALL_REPO=tap-images
export TAP_VERSION=1.8.0
# image copy from Tanzu network to your local machine and then to ECR on the fly
imgpkg copy --concurrency 1 -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}

# Good coffee break time, this step take times moving ~249 images from registry.tanzu.vmware.com to AWS ECR created earlier
# This step fail timeout sometimes. Just clear the whole terminal session and restart from this page
# One key reason of failure is "aws ecr get-login-password --region $AWS_REGION" only valid for 12 hours
# Use the following docker command to check if you could login to ECR using the latest password
# docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com | `aws ecr get-login-password --region $AWS_REGION`
# docker login –u AWS –p password –e none https://$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
# Add the Tanzu Application Platform package repository to the cluster by running:
kubectl create ns tap-install
tanzu package repository add tanzu-tap-repository \
  --url ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REPO}:${TAP_VERSION} \
  --namespace tap-install
# Validate if those Image actually copied to your ECR repo

aws ecr describe-images --repository-name $INSTALL_REPO --output text

# docker pull 548625820784.dkr.ecr.eu-west-1.amazonaws.com/tap-images:sha256-6e451d3d69226a73c03d943353ed6c761803dfa41da8860b7b464ab6f3861334.imgpkg
# Check if it works
# Expect something like : 
# - Retrieving repository tap...
# NAME:          tanzu-tap-repository
# VERSION:       16253001
# REPOSITORY:    123456789012.dkr.ecr.us-west-2.amazonaws.com/tap-images
# TAG:           1.5.2
# STATUS:        Reconcile succeeded
# REASON:
tanzu package repository get tanzu-tap-repository --namespace tap-install
tanzu package available list --namespace tap-install
tanzu package available list tap.tanzu.vmware.com --namespace tap-install
# Generate your tap-values.yaml file  
cat << EOF > tap-values-doc-1.8-aws.yaml
shared:
  ingress_domain: "INGRESS-DOMAIN"

ceip_policy_disclosed: true

profile: full # Can take iterate, build, run, view.

supply_chain: basic # Can take testing, testing_scanning.

ootb_supply_chain_basic: # Based on supply_chain set above, can be changed to ootb_supply_chain_testing, ootb_supply_chain_testing_scanning.
  registry:
    server: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
    # The prefix of the ECR repository.  Workloads will need
    # two repositories created:
    #
    # tanzu-application-platform/<workloadname>-<namespace>
    # tanzu-application-platform/<workloadname>-<namespace>-bundle
    repository: tanzu-application-platform

contour:
  envoy:
    service:
      type: LoadBalancer # This is set by default, but can be overridden by setting a different value.

buildservice:
  kp_default_repository: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/tap-build-service
  # Enable the build service k8s service account to bind to the AWS IAM Role
  kp_default_repository_aws_iam_role_arn: "arn:aws:iam::${AWS_ACCOUNT_ID}:role/tap-build-service"

local_source_proxy:
  repository: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/local-source
  push_secret:
    aws_iam_role_arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/tap-local-source-proxy

ootb_templates:
  # Enable the config writer service to use cloud based iaas authentication
  # which are retrieved from the developer namespace service account by
  # default
  iaas_auth: true

tap_gui:
  app_config:
    auth:
      allowGuestAccess: true  # This allows unauthenticated users to log in to your portal. If you want to deactivate it, make sure you configure an alternative auth provider.
    catalog:
      locations:
        - type: url
          target: https://GIT-CATALOG-URL/catalog-info.yaml

metadata_store:
  ns_for_export_app_cert: "MY-DEV-NAMESPACE" # Verify this namespace is available within your cluster before initiating the Tanzu Application Platform installation.
  app_service_type: ClusterIP # Defaults to LoadBalancer. If shared.ingress_domain is set earlier, this must be set to ClusterIP.

namespace_provisioner:
  aws_iam_role_arn: "arn:aws:iam::${AWS_ACCOUNT_ID}:role/tap-workload"

tap_telemetry:
  customer_entitlement_account_number: "CUSTOMER-ENTITLEMENT-ACCOUNT-NUMBER" # (Optional) Identify data for creating Tanzu Application Platform usage reports.
EOF
# (Optional) Fix the bug that K8s PVC could not be provisioned
# This is the storageclass that Kind uses
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
# set the storage class as default
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
# Install TAP
tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file tap-values-ref/tap-values-doc-1.8-aws.yaml -n tap-install
# Verify the package install by running:
tanzu package installed get tap -n tap-install
# Verify that the necessary packages in the profile are installed by running:
tanzu package installed list -A
# Update TAP with tap-values.yaml
tanzu package installed update tap -p tap.tanzu.vmware.com --version $TAP_VERSION --values-file tap-values-ref/tap-values-doc-1.8-aws.yaml -n tap-install
# Delete TAP
tanzu package installed delete tap --namespace tap-install -y
# Add A Record to AWS Route53 with alias to Ingress 
# Get your domain name Hosted Zone ID
export AWS_HOSTED_ZONE_ID=`aws route53 list-hosted-zones-by-name | 
jq --arg name "yourdomain.net." \
-r '.HostedZones | .[] | select(.Name=="\($name)") | .Id'`
# List existing resource record sets
aws route53 list-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID
# Get ingress ELB address and ELB Hosted Zone usin kubectl and ELB CLI
export AWS_TAP_INGRESS_ELB=`kubectl get svc envoy -n tanzu-system-ingress \
--output jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
# Classic LB
export AWS_ELB_HOSTED_ZONE_ID=`aws elb describe-load-balancers | jq --arg name $AWS_TAP_INGRESS_ELB -r '.LoadBalancerDescriptions | .[] | select(.DNSName=="\($name)") | .CanonicalHostedZoneNameID'`
# NLB
export AWS_ELB_HOSTED_ZONE_ID=`aws elbv2 describe-load-balancers | jq --arg name $AWS_TAP_INGRESS_ELB -r '.LoadBalancers | .[] | select(.DNSName=="\($name)") | .CanonicalHostedZoneId'`
# UPSERT Record to Route53
aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch '{"Changes": [ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "tap.jkwongdemo.net", "Type": "A", "AliasTarget":{ "HostedZoneId": "'$AWS_ELB_HOSTED_ZONE_ID'" ,"DNSName": "'$AWS_TAP_INGRESS_ELB'","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch '{"Changes": [ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "tap-gui.tap.jkwongdemo.net", "Type": "A", "AliasTarget":{ "HostedZoneId": "'$AWS_ELB_HOSTED_ZONE_ID'" ,"DNSName": "'$AWS_TAP_INGRESS_ELB'","EvaluateTargetHealth": false} } } ]}'
# Remove Record after testing (change action from UPSERT to DELETE)
aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch '{"Changes": [ { "Action": "DELETE", "ResourceRecordSet": { "Name": "tap.jkwongdemo.net", "Type": "A", "AliasTarget":{ "HostedZoneId": "'$AWS_ELB_HOSTED_ZONE_ID'" ,"DNSName": "'$AWS_TAP_INGRESS_ELB'","EvaluateTargetHealth": false} } } ]}'
aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch '{"Changes": [ { "Action": "DELETE", "ResourceRecordSet": { "Name": "tap-gui.tap.jkwongdemo.net", "Type": "A", "AliasTarget":{ "HostedZoneId": "'$AWS_ELB_HOSTED_ZONE_ID'" ,"DNSName": "'$AWS_TAP_INGRESS_ELB'","EvaluateTargetHealth": false} } } ]}'
aws route53 list-resource-record-sets 
