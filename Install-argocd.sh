#!/bin/bash
# ============================================================
# install-argocd.sh
# Installs ArgoCD on the dev-cluster KinD cluster
# Run as root: bash install-argocd.sh
# ============================================================
set -e

KUBECONFIG=/root/.kube/config
export KUBECONFIG

echo "════════════════════════════════════════"
echo "  Installing ArgoCD on dev-cluster"
echo "════════════════════════════════════════"

# ── Step 1: Create namespace ──────────────────────────────
echo ""
echo "▶ Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# ── Step 2: Install ArgoCD ────────────────────────────────
echo ""
echo "▶ Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ── Step 3: Wait for ArgoCD to be ready ───────────────────
echo ""
echo "▶ Waiting for ArgoCD pods to be ready (this takes ~2 min)..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server \
  deployment/argocd-repo-server \
  deployment/argocd-applicationset-controller \
  -n argocd

# ── Step 4: Patch argocd-server to NodePort ───────────────
echo ""
echo "▶ Exposing ArgoCD server as NodePort..."
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30443, "protocol": "TCP", "name": "https"}]}}'

# ── Step 5: Get initial admin password ────────────────────
echo ""
echo "▶ Getting initial admin password..."
sleep 10
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "════════════════════════════════════════"
echo "  ✅ ArgoCD installed successfully!"
echo "════════════════════════════════════════"
echo ""
echo "  URL      : https://192.168.150.135:30443"
echo "  Username : admin"
echo "  Password : $ARGOCD_PASSWORD"
echo ""
echo "  To login via CLI:"
echo "  argocd login 192.168.150.135:30443 --username admin --password '$ARGOCD_PASSWORD' --insecure"
echo ""

# ── Step 6: Copy kubeconfig to minajohn ───────────────────
cp /root/.kube/config /home/minajohn/.kube/config
chown minajohn:minajohn /home/minajohn/.kube/config
echo "  ✅ Kubeconfig copied to minajohn"
