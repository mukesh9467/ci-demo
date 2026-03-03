#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  EKS Cluster Deployment Script${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform.${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found${NC}"
echo ""

# Navigate to terraform directory
cd "$(dirname "$0")"

echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo ""
echo -e "${YELLOW}Generating plan...${NC}"
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}Reviewing plan above. Ready to apply? (yes/no)${NC}"
read -r response

if [ "$response" != "yes" ]; then
    echo -e "${YELLOW}Cancelled by user${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Applying Terraform configuration...${NC}"
echo -e "${YELLOW}This will take 15-20 minutes...${NC}"
terraform apply tfplan

echo ""
echo -e "${GREEN}✅ Infrastructure created successfully!${NC}"
echo ""

# Get outputs
echo -e "${YELLOW}Configuring kubectl...${NC}"
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw cluster_endpoint | awk -F. '{print $3}')

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo -e "${GREEN}✅ kubectl configured${NC}"
echo ""

echo -e "${YELLOW}Waiting for nodes to be ready...${NC}"
sleep 30
kubectl wait --for=condition=ready node --all --timeout=300s || true

echo ""
echo -e "${YELLOW}Verifying cluster...${NC}"
kubectl get nodes
echo ""

echo -e "${YELLOW}Verifying ArgoCD...${NC}"
kubectl get pods -n argocd
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Cluster Ready!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Cluster Info:"
terraform output -raw configure_kubectl
echo ""
echo "Next steps:"
echo "1. Configure ECR login: aws ecr get-login-password | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com"
echo "2. Access ArgoCD:"
echo "   kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo "3. Get your application URL:"
echo "   kubectl get svc ci-demo-app -n ci-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo ""
