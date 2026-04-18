sed -i 's#image: microservices/adminfrontend#image: microservices/microservicesadminfrontend#g' k8s/adminfrontend.yaml
sed -i 's#image: microservices/webfrontend#image: microservices/microserviceswebfrontend#g' k8s/webfrontend.yaml
sed -i 's#image: microservices/paymentservice#image: microservices/paymentserviceendpoint#g' k8s/paymentservice.yaml

# This loop adds ":latest" to all the microservice YAMLs
for file in k8s/adminfrontend.yaml k8s/apigatewayadmin.yaml k8s/apigatewayforweb.yaml k8s/basketservice.yaml k8s/discountservice.yaml k8s/identityservice.yaml k8s/orderservice.yaml k8s/paymentservice.yaml k8s/productservice.yaml k8s/webfrontend.yaml; do
  sed -i -E '/image: / s|([^:])$|\1:latest|' "$file"
done
