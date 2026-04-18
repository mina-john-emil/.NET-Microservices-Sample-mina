```bash
chmod +x CorrectForLocalK8s.sh
./CorrectForLocalK8s.sh
docker system prune -a --volumes
docker compose build
chmod +x kind-load.sh
./kind-load.sh
kubectl apply -f k8s/
kubectl patch deployment orderservice-deployment --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "DatabaseSettings__ConnectionString", "value": "mongodb://mongo-service:27017"}}]'
kubectl get pods
```
