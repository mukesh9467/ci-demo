# ArgoCD Helm Chart Installation
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.0"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      global = {
        logging = {
          level = "info"
        }
      }
      configs = {
        secret = {
          argocdServerAdminPassword = bcrypt(random_password.argocd_password.result)
        }
      }
      server = {
        service = {
          type = "LoadBalancer"
        }
        extraArgs = [
          "--insecure"
        ]
      }
      applicationController = {
        replicas = 1
      }
      repoServer = {
        replicas = 1
      }
      controller = {
        replicas = 1
      }
    })
  ]

  depends_on = [aws_eks_node_group.main]
}

# Generate random password for ArgoCD admin
resource "random_password" "argocd_password" {
  length  = 32
  special = true
}

# Kubernetes secret for ArgoCD credentials
resource "kubernetes_secret" "argocd_credentials" {
  metadata {
    name      = "argocd-credentials"
    namespace = "argocd"
  }

  data = {
    admin_password = random_password.argocd_password.result
  }

  depends_on = [helm_release.argocd]
}

# Annotation to update deployment when image changes
resource "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server-lb"
    namespace = "argocd"
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  depends_on = [helm_release.argocd]
}
