# Post-Deployment Verification Script
# Runs after terraform apply completes

$ErrorActionPreference = "Stop"
$region = "ap-south-1"
$clusterName = "ci-demo-eks"
$namespace = "ci-demo"

Write-Host "====== POST-DEPLOYMENT VERIFICATION ======" -ForegroundColor Cyan

# 1. Configure kubectl
Write-Host ""
Write-Host "[1/5] Configuring kubectl access..." -ForegroundColor Yellow
try {
    aws eks update-kubeconfig --region $region --name $clusterName
    Write-Host "✓ kubectl configured successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to configure kubectl: $_" -ForegroundColor Red
    exit 1
}

# Wait for cluster API availability
Write-Host "[1b/5] Waiting for cluster API to be ready..." -ForegroundColor Yellow
$retries = 0
while ($retries -lt 30) {
    try {
        kubectl cluster-info | Out-Null
        Write-Host "✓ Cluster API is ready" -ForegroundColor Green
        break
    } catch {
        $retries++
        if ($retries -lt 30) {
            Write-Host "  API not ready yet (attempt $retries/30), waiting 10 seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds 10
        }
    }
}

if ($retries -eq 30) {
    Write-Host "✗ Cluster API did not become ready" -ForegroundColor Red
    exit 1
}

# 2. Check cluster nodes
Write-Host ""
Write-Host "[2/5] Checking worker nodes..." -ForegroundColor Yellow
$nodes = kubectl get nodes --no-headers 2>/dev/null
if ($nodes) {
    Write-Host "✓ Worker nodes:" -ForegroundColor Green
    kubectl get nodes -o wide
} else {
    Write-Host "⚠ No nodes found yet (still provisioning)" -ForegroundColor Yellow
}

# 3. Check ArgoCD installation
Write-Host ""
Write-Host "[3/5] Checking ArgoCD installation..." -ForegroundColor Yellow
$argocdPods = kubectl get pods -n argocd --no-headers 2>/dev/null | Measure-Object | Select-Object -ExpandProperty Count
if ($argocdPods -gt 0) {
    Write-Host "✓ ArgoCD is installed ($argocdPods pods)" -ForegroundColor Green
    kubectl get pods -n argocd
    
    # Get ArgoCD admin password
    Write-Host ""
    Write-Host "[3b/5] Retrieving ArgoCD admin credentials..." -ForegroundColor Yellow
    $password = kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | certutil -decode -
    Write-Host "ArgoCD Admin Credentials:" -ForegroundColor Green
    Write-Host "  Username: admin"
    Write-Host "  Password: (check kubectl secret)"
} else {
    Write-Host "⚠ ArgoCD not yet installed (still provisioning)" -ForegroundColor Yellow
}

# 4. Check application deployment
Write-Host ""
Write-Host "[4/5] Checking application deployment..." -ForegroundColor Yellow
$appPods = kubectl get pods -n $namespace --no-headers 2>/dev/null | Measure-Object | Select-Object -ExpandProperty Count
if ($appPods -gt 0) {
    Write-Host "✓ Application deployed ($appPods pods)" -ForegroundColor Green
    kubectl get pods -n $namespace -o wide
    
    Write-Host ""
    Write-Host "Getting LoadBalancer URL..." -ForegroundColor Gray
    $svc = kubectl get svc -n $namespace -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null
    if ($svc) {
        Write-Host "✓ Application URL: http://$svc" -ForegroundColor Green
    } else {
        Write-Host "⚠ LoadBalancer URL not yet assigned" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Application pods not yet deployed (waiting for ArgoCD sync)" -ForegroundColor Yellow
}

# 5. Check namespace status
Write-Host ""
Write-Host "[5/5] Checking namespaces..." -ForegroundColor Yellow
kubectl get namespaces

Write-Host ""
Write-Host "====== VERIFICATION COMPLETE ======" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. Wait for all pods to reach 'Running' status"
Write-Host "  2. Test application: curl http://<LoadBalancer-URL>/"
Write-Host "  3. Push code to GitHub to trigger CI/CD pipeline"
Write-Host "  4. Monitor: kubectl get events -n $namespace"
