```bash
chmod +x CorrectForLocalK8s.sh
./CorrectForLocalK8s.sh
docker system prune -a --volumes
docker compose build
chmod +x kind-load.sh
./kind-load.sh
kubectl apply -f k8s/
kubectl set env deployment/orderservice-deployment \
  DatabaseSettings__ConnectionString="mongodb://mongo-service:27017"

kubectl get pods
```
