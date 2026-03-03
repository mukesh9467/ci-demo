# CI/CD Demo: Python FastAPI Application on AWS EKS

This is a complete end-to-end CI/CD pipeline demonstration for a Python FastAPI application deployed on AWS EKS with ArgoCD.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  CI Pipeline │───→│  ECR Images  │───→│ CD Pipeline  │  │
│  │  (Python,    │    │  - latest    │    │ (K8s Deploy) │  │
│  │   Linting,   │    │  - <sha>     │    │              │  │
│  │   Tests,     │    │              │    │ Deploys via  │  │
│  │   Security)  │    │              │    │ - kubectl    │  │
│  └──────────────┘    │              │    │ - ArgoCD     │  │
│                       └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              └──────────────┐
                                             │
                    ┌────────────────────────┘
                    │
            ┌───────────────────────┐
            │   AWS EKS Cluster     │
            │  (ap-south-1)         │
            │                       │
            │  ┌─────────────────┐  │
            │  │  ci-demo-app    │  │
            │  │  (2 replicas)   │  │
            │  └─────────────────┘  │
            │                       │
            │  ┌─────────────────┐  │
            │  │ ArgoCD (GitOps) │  │
            │  │ Continuous Sync │  │
            │  └─────────────────┘  │
            │                       │
            │  ┌─────────────────┐  │
            │  │   LoadBalancer  │  │
            │  │   (Public Access)│  │
            │  └─────────────────┘  │
            └───────────────────────┘
```

## Pipeline Flow

### 1. CI Pipeline (Triggered on push to main)
- ✅ Code formatting check (Black)
- ✅ Linting (Flake8)
- ✅ Unit tests (pytest)
- ✅ Dependency scan (pip-audit)
- ✅ Security scan (Bandit)
- ✅ Build Docker image
- ✅ Security scan Docker image (Trivy)
- ✅ Push to ECR with tags: `<short-sha>` and `latest`

### 2. CD Pipeline (Auto-triggered after CI success)
- ✅ Get latest image from ECR
- ✅ Update Kubernetes deployment
- ✅ Monitor rollout
- ✅ Run smoke tests
- ✅ Verify deployment health

## Project Structure

```
ci-demo/
├── app.py                          # FastAPI application
├── tests/test_app.py              # Unit tests
├── requirements.txt               # Python dependencies
├── Dockerfile                     # Docker image definition
├── pytest.ini                     # Pytest configuration
│
├── .github/workflows/
│   ├── ci.yml                     # CI Pipeline
│   └── cd.yml                     # CD Pipeline
│
├── terraform/                     # Infrastructure as Code
│   ├── variables.tf
│   ├── main.tf
│   ├── vpc.tf
│   ├── security_groups.tf
│   ├── iam.tf
│   ├── eks.tf
│   ├── argocd.tf
│   ├── outputs.tf
│   ├── .gitignore
│   ├── deploy.sh                 # Deployment script
│   └── README.md
│
└── k8s/                          # Kubernetes manifests
    ├── namespace.yaml
    ├── deployment.yaml
    ├── service.yaml
    ├── argocd-namespace.yaml
    └── argocd-application.yaml
```

## Quick Start

### Prerequisites

Ensure you have installed:
- Terraform >= 1.0
- AWS CLI (configured with credentials)
- kubectl
- Helm 3.x
- Docker (for local testing)

### Step 1: Deploy Infrastructure

```bash
cd terraform
chmod +x deploy.sh
./deploy.sh

# Or manually:
terraform init
terraform plan
terraform apply
```

**Time**: 15-20 minutes
**Cost**: ~$0.13/hour (EKS + EC2)

### Step 2: Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name ci-demo-eks
kubectl get nodes
```

### Step 3: Verify ArgoCD

```bash
# Get ArgoCD admin password
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Get ArgoCD URL
kubectl get svc -n argocd argocd-server \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 4: Verify Application

```bash
# Get application URL
kubectl get svc ci-demo-app -n ci-demo \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test the app
curl http://<APP_URL>/
```

### Step 5: Push Code to Trigger CI/CD

```bash
git add .
git commit -m "Deploy full CI/CD pipeline"
git push origin main
```

Monitor the pipeline:
1. GitHub Actions → CI pipeline runs
2. On success, CD pipeline auto-triggers
3. Deployment will be updated in EKS
4. Check ArgoCD for sync status

## Testing Locally

### Build Docker Image

```bash
docker build -t python/demo:test .
docker run -p 8000:8000 python/demo:test
```

### Run Tests

```bash
python -m pytest tests/ -v
```

### Check Code Quality

```bash
black . --check
flake8 .
bandit -r . --exclude ./tests
```

## Key Features

### Security
- ✅ Alpine base image (smaller attack surface)
- ✅ Non-root container user
- ✅ Read-only root filesystem
- ✅ No privilege escalation
- ✅ Security scans (Bandit, Trivy)
- ✅ Dependency scanning (pip-audit)

### High Availability
- ✅ 2 application replicas
- ✅ Rolling updates
- ✅ Liveness & readiness probes
- ✅ 2 NAT gateways for HA

### CI/CD Best Practices
- ✅ Automated testing on every push
- ✅ GitOps deployment (ArgoCD)
- ✅ Auto-sync configuration
- ✅ Rollback capabilities
- ✅ Smoke tests after deployment

### Monitoring & Observability
- ✅ EKS control plane logs enabled
- ✅ Resource limits configured
- ✅ Health checks (liveness + readiness)
- ✅ Service LoadBalancer endpoint

## Customization

### Change Cluster Size

Edit `terraform/variables.tf`:
```hcl
variable "desired_size" {
  default = 3  # Change from 2 to 3 nodes
}
```

### Change Image Registry

Update `k8s/deployment.yaml`:
```yaml
image: your-account.dkr.ecr.your-region.amazonaws.com/your-repo:latest
```

### Change Application Port

Update `app.py` and `k8s/deployment.yaml` to match.

## Cleanup

⚠️ **This will delete all AWS resources!**

```bash
cd terraform
terraform destroy
```

## Cost Optimization Tips

1. **Auto-scale down**: Use Spot instances for cost savings
2. **Schedule clusters**: Stop clusters during off-hours
3. **Use Fargate**: For variable workloads instead of EC2
4. **Monitor**: Set up CloudWatch alarms for cost anomalies

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod -n ci-demo <pod-name>
kubectl logs -n ci-demo <pod-name>
```

### Service has no external IP
```bash
# Wait a few minutes for load balancer provisioning
kubectl get svc ci-demo-app -n ci-demo -w
```

### ArgoCD not syncing
```bash
kubectl logs -n argocd deployment/argocd-application-controller
```

### ECR image pull errors
```bash
# Verify node IAM policy allows ECR access
kubectl describe nodes
```

## Further Reading

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/overview/)

## Support

For issues, check:
1. Terraform apply logs
2. kubectl describe/logs commands
3. GitHub Actions workflow logs
4. CloudWatch logs in AWS Console

## License

This is a demonstration project. Use freely for learning.
