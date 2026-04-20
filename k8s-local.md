```bash
docker system prune -a --volumes
docker compose build

kubectl apply -f k8s/
# Check firewall status
firewall-cmd --state

# Open all NodePorts
firewall-cmd --permanent --add-port=31443/tcp
firewall-cmd --permanent --add-port=31298/tcp
firewall-cmd --permanent --add-port=31720/tcp
firewall-cmd --permanent --add-port=31672/tcp
firewall-cmd --permanent --add-port=31023/tcp
firewall-cmd --permanent --add-port=30023/tcp
firewall-cmd --permanent --add-port=31114/tcp
firewall-cmd --permanent --add-port=31602/tcp
firewall-cmd --permanent --add-port=31705/tcp
firewall-cmd --permanent --add-port=31104/tcp

# Reload firewall
firewall-cmd --reload

# Verify ports are open
firewall-cmd --list-ports

# Kill all broken port-forwards
kill $(jobs -p) 2>/dev/null
sleep 3

# Wait for new pods to be ready
kubectl wait --for=condition=ready pod -l app=webfrontend --timeout=60s
kubectl wait --for=condition=ready pod -l app=adminfrontend --timeout=60s
kubectl wait --for=condition=ready pod -l app=identityservice --timeout=60s

kubectl port-forward --address 0.0.0.0 deployment/webfrontend-deployment 31443:8080 &
kubectl port-forward --address 0.0.0.0 deployment/adminfrontend-deployment 31298:8080 &
kubectl port-forward --address 0.0.0.0 deployment/identityservice-deployment 31720:8080 &
kubectl port-forward --address 0.0.0.0 service/rabbitmq-clusterip-srv 31672:15672 &


sleep 2
echo "All forwards running:"
jobs



kubectl get pods
```
