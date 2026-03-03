# EKS Cluster Infrastructure Setup

This directory contains Terraform configuration to provision a complete AWS EKS cluster with all required components.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **kubectl** installed
5. **Helm** (3.0+) installed

## Files

- `variables.tf` - Input variables for the cluster
- `main.tf` - Provider configuration
- `vpc.tf` - VPC, subnets, NAT gateways, and route tables
- `security_groups.tf` - Security groups for control plane and worker nodes
- `iam.tf` - IAM roles and policies
- `eks.tf` - EKS cluster and node group
- `argocd.tf` - ArgoCD Helm release
- `outputs.tf` - Output values

## Default Configuration

- **Region**: ap-south-1
- **Cluster Name**: ci-demo-eks
- **VPC CIDR**: 10.0.0.0/16
- **Worker Nodes**: 2 (t3.medium)
- **Kubernetes Version**: 1.28

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Review and Customize

```bash
# Edit variables.tf to customize the cluster config
# Then review the plan
terraform plan
```

### 3. Apply Infrastructure

```bash
terraform apply
```

This will take **15-20 minutes** to complete. It creates:
- VPC with public and private subnets
- NAT gateways for private subnet egress
- EKS control plane
- 2 worker nodes
- ArgoCD installation
- IAM roles for IRSA

### 4. Configure kubectl

```bash
# Get the command from Terraform output
aws eks update-kubeconfig --region ap-south-1 --name ci-demo-eks
```

### 5. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Accessing ArgoCD

### Get ArgoCD Password

```bash
# From Terraform output or:
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Username: admin
```

### Access ArgoCD UI

```bash
# Get LoadBalancer URL
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or port-forward if LoadBalancer not available
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Access: https://localhost:8080
```

## Accessing Your Application

```bash
# Get service URL
kubectl get svc ci-demo-app -n ci-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or test directly
curl http://<LOAD_BALANCER_URL>/
```

## CI/CD Integration

The CI pipeline will:
1. Build Docker image
2. Push to ECR with tags: `<short-sha>` and `latest`
3. Trigger CD pipeline automatically

The CD pipeline will:
1. Pull latest image
2. Update deployment in Kubernetes
3. Run smoke tests

## Cleaning Up

⚠️ **This will delete all infrastructure!**

```bash
terraform destroy
```

## Troubleshooting

### Nodes not ready
```bash
kubectl describe nodes
kubectl logs -n kube-system -l k8s-app=aws-node
```

### ArgoCD not syncing
```bash
# Check ArgoCD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Pods not starting
```bash
kubectl describe pod <pod-name> -n ci-demo
kubectl logs <pod-name> -n ci-demo
```

## Costs

Using `t3.medium` instances (2 nodes) in ap-south-1:
- Roughly **$0.03-0.04 per hour**
- **~$25-30 per month** for compute (EC2)
- EKS control plane: **$0.10 per hour** (~$73/month)
- **Total: ~$100/month** (includes EBS, NAT gateway, data transfer)

Don't forget to **destroy** when done!
