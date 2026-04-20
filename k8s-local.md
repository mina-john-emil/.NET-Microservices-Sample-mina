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



# Update configmap with correct VM IP for all service URLs
kubectl patch configmap microservices-config \
  --type merge \
  -p '{
    "data": {
      "Identity__Uri": "http://<your ip>:31720",
      "MicroServiceAddress__AdminApiGateway__Uri": "http://<your ip>:31023",
      "MicroserviceAddress__ApiGatewayForWeb__Uri": "http://<your ip>:30023",
      "MicroServiceAddress__Product__Uri": "http://<your ip>:31114",
      "MicroServiceAddress__Discount__Uri": "http://<your ip>:31600",
      "MicroServiceAddress__DiscountGrpc__Uri": "http://<your ip>:31600"
    }
  }'

# identityservice must redirect back to your real VM IP after login
kubectl set env deployment/identityservice-deployment \
  WebFrontend__Uri="http://<your ip>:31443" \
  AdminFrontend__Uri="http://<your ip>:31298"

# Restart all services so they pick up new configmap values
kubectl rollout restart deployment/identityservice-deployment
kubectl rollout restart deployment/basketservice-deployment
kubectl rollout restart deployment/orderservice-deployment
kubectl rollout restart deployment/adminfrontend-deployment
kubectl rollout restart deployment/webfrontend-deployment
kubectl rollout restart deployment/apigatewayadmin-deployment
kubectl rollout restart deployment/apigatewayforweb-deployment

# Wait for all to be ready
kubectl rollout status deployment/identityservice-deployment --timeout=60s
kubectl rollout status deployment/webfrontend-deployment --timeout=60s
kubectl rollout status deployment/adminfrontend-deployment --timeout=60s

# Kill old forwards
kill $(jobs -p) 2>/dev/null
sleep 3

# Get new pod names after restart
WEB_POD=$(kubectl get pod -l app=webfrontend -o jsonpath='{.items[0].metadata.name}')
ADMIN_POD=$(kubectl get pod -l app=adminfrontend -o jsonpath='{.items[0].metadata.name}')
IDENTITY_POD=$(kubectl get pod -l app=identityservice -o jsonpath='{.items[0].metadata.name}')

echo "Web:      $WEB_POD"
echo "Admin:    $ADMIN_POD"
echo "Identity: $IDENTITY_POD"

# Port-forward using correct ports
kubectl port-forward --address 0.0.0.0 pod/$WEB_POD 31443:8080 &
kubectl port-forward --address 0.0.0.0 pod/$ADMIN_POD 31298:8080 &
kubectl port-forward --address 0.0.0.0 pod/$IDENTITY_POD 31720:8080 &
kubectl port-forward --address 0.0.0.0 service/rabbitmq-clusterip-srv 31672:15672 &

sleep 2
jobs

sleep 2
echo "All forwards running:"
jobs



kubectl get pods
```
