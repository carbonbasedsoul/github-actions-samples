#!/bin/bash
set -e
echo "setting up argocd on gke..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
echo "admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/carbonbasedsoul/github-actions-samples
    targetRevision: argocd-gitops
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: hello-gitops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
echo "done. access ui: kubectl port-forward svc/argocd-server -n argocd 8080:443"
