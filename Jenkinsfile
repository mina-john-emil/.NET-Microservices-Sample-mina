pipeline {
    // Run on any available Jenkins agent
    agent any

    // Environment variables available to ALL stages
    environment {
        // Docker registry prefix — matches your image names
        REGISTRY = "microservices"

        // Git repo URL
        GIT_REPO = "https://github.com/mina-john-emil/.NET-Microservices-Sample-mina.git"

        // Your VM IP — used for K8s deployment
        VM_IP = "192.168.150.131"

        // Image tag — uses Jenkins build number for traceability
        // e.g. build #5 → microservices/orderservice:5
        IMAGE_TAG = "${BUILD_NUMBER}"

        // Kubernetes namespace
        K8S_NAMESPACE = "default"
    }

    stages {

        // ── Stage 1: Checkout ─────────────────────────────────
        // Clones your GitHub repo onto the Jenkins agent
        stage('Checkout') {
            steps {
                echo "Cloning repo from GitHub..."
                git branch: 'main',
                    url: "${GIT_REPO}"
                echo "Checkout done ✅"
            }
        }

        // ── Stage 2: Build Docker Images ──────────────────────
        // Builds all 10 microservice Docker images
        // Each service has its own Dockerfile
        stage('Build Images') {
            steps {
                echo "Building all Docker images..."
                script {
                    // List of all services with their Dockerfile paths
                    def services = [
                        [name: 'orderservice',
                         context: '.',
                         dockerfile: 'src/Services/Orders/OrderService/Dockerfile'],

                        [name: 'basketservice',
                         context: '.',
                         dockerfile: 'src/Services/Baskets/BasketService/Dockerfile'],

                        [name: 'discountservice',
                         context: '.',
                         dockerfile: 'src/Services/Discounts/DiscountService/Dockerfile'],

                        [name: 'productservice',
                         context: '.',
                         dockerfile: 'src/Services/Products/ProductService/Dockerfile'],

                        [name: 'paymentserviceendpoint',
                         context: '.',
                         dockerfile: 'src/Services/Payments/Presentation/PaymentService.EndPoint/Dockerfile'],

                        [name: 'identityservice',
                         context: '.',
                         dockerfile: 'src/Identity/IdentityService/Dockerfile'],

                        [name: 'apigatewayadmin',
                         context: '.',
                         dockerfile: 'src/ApiGateways/ApiGateway.Admin/Dockerfile'],

                        [name: 'apigatewayforweb',
                         context: '.',
                         dockerfile: 'src/ApiGateways/ApiGatewayForWeb/Dockerfile'],

                        [name: 'microservicesadminfrontend',
                         context: '.',
                         dockerfile: 'src/Web/Microservices.Admin.Frontend/Dockerfile'],

                        [name: 'microserviceswebfrontend',
                         context: '.',
                         dockerfile: 'src/Web/Microservices.Web.Frontend/Microservices.Web.Frontend/Dockerfile'],
                    ]

                    // Build each image
                    // Tag with both :BUILD_NUMBER and :latest
                    services.each { svc ->
                        echo "Building ${svc.name}..."
                        sh """
                            docker build \
                                -t ${REGISTRY}/${svc.name}:${IMAGE_TAG} \
                                -t ${REGISTRY}/${svc.name}:latest \
                                -f ${svc.dockerfile} \
                                ${svc.context}
                        """
                        echo "${svc.name} built ✅"
                    }
                }
            }
        }

        // ── Stage 3: Run Tests ────────────────────────────────
        // Runs unit and integration tests
        // If any test fails, pipeline stops here — no bad code deployed
        stage('Test') {
            steps {
                echo "Running tests..."
                script {
                    // Test projects in the repo
                    def testProjects = [
                        'src/Services/Products/tests/ProductService.Test/ProductService.UnitTests.csproj',
                        'src/Services/Products/tests/ProductServiceComponent.Test/ProductService.ComponentTests.csproj',
                        'src/Services/Orders/tests/OrderService.ContractTests/OrderService.ContractTests.csproj',
                    ]

                    testProjects.each { proj ->
                        // Check if test project exists before running
                        def exists = sh(
                            script: "[ -f '${proj}' ] && echo yes || echo no",
                            returnStdout: true
                        ).trim()

                        if (exists == 'yes') {
                            echo "Running tests: ${proj}"
                            sh "dotnet test ${proj} --no-build --verbosity normal"
                        } else {
                            echo "Skipping ${proj} (not found)"
                        }
                    }
                }
                echo "Tests passed ✅"
            }
        }

        // ── Stage 4: Load Images into Kind ───────────────────
        // kind cluster can't pull from external registry
        // We load images directly from Docker daemon into kind
        // This replaces "docker push" for local development
        stage('Load Images to Kind') {
            steps {
                echo "Loading images into kind cluster..."
                script {
                    def images = [
                        'orderservice',
                        'basketservice',
                        'discountservice',
                        'productservice',
                        'paymentserviceendpoint',
                        'identityservice',
                        'apigatewayadmin',
                        'apigatewayforweb',
                        'microservicesadminfrontend',
                        'microserviceswebfrontend',
                    ]

                    images.each { img ->
                        echo "Loading ${img}..."
                        sh """
                            kind load docker-image \
                                --name dev-cluster \
                                ${REGISTRY}/${img}:${IMAGE_TAG}
                        """
                    }
                }
                echo "All images loaded ✅"
            }
        }

        // ── Stage 5: Deploy with Helm ─────────────────────────
        // Uses Helm to deploy/upgrade all services
        // --install = install if not exists, upgrade if exists
        // --set global.imageTag = uses the build number tag
        // --wait = wait until all pods are ready
        // --timeout = fail if not ready within 5 minutes
        stage('Deploy') {
            steps {
                echo "Deploying to Kubernetes..."
                sh """
                    helm upgrade --install microservices helm/microservices/ \
                        --namespace ${K8S_NAMESPACE} \
                        --set global.imageTag=${IMAGE_TAG} \
                        --set global.vmIP=${VM_IP} \
                        --wait \
                        --timeout 5m
                """
                echo "Deployment done ✅"
            }
        }

        // ── Stage 6: Verify Deployment ────────────────────────
        // Checks all pods are Running after deployment
        // Fails the pipeline if any pod is not healthy
        stage('Verify') {
            steps {
                echo "Verifying all pods are running..."
                sh """
                    echo "=== Pod Status ==="
                    kubectl get pods -n ${K8S_NAMESPACE}

                    echo "=== Services ==="
                    kubectl get services -n ${K8S_NAMESPACE}

                    echo "=== Helm Release ==="
                    helm status microservices -n ${K8S_NAMESPACE}

                    # Check if any pod is NOT running
                    NOT_RUNNING=\$(kubectl get pods -n ${K8S_NAMESPACE} \
                        --field-selector=status.phase!=Running \
                        --no-headers 2>/dev/null | grep -v "Completed" | wc -l)

                    if [ "\$NOT_RUNNING" -gt "0" ]; then
                        echo "ERROR: Some pods are not running!"
                        kubectl get pods -n ${K8S_NAMESPACE}
                        exit 1
                    fi

                    echo "All pods running ✅"
                """
            }
        }
    }

    // ── Post actions — run after all stages ───────────────────
    post {
        success {
            echo """
            ╔══════════════════════════════════════╗
            ║   DEPLOYMENT SUCCESSFUL! ✅           ║
            ║                                      ║
            ║   Build: #${BUILD_NUMBER}            ║
            ║   Web:   http://${VM_IP}:31443       ║
            ║   Admin: http://${VM_IP}:31298       ║
            ║   Identity: http://${VM_IP}:31720    ║
            ║   RabbitMQ: http://${VM_IP}:31672    ║
            ╚══════════════════════════════════════╝
            """
        }
        failure {
            echo "❌ Pipeline FAILED at stage: ${STAGE_NAME}"
            // Show logs of failed pods for debugging
            sh """
                echo "=== Failed Pods ==="
                kubectl get pods -n ${K8S_NAMESPACE} | grep -v Running || true
                echo "=== Recent Events ==="
                kubectl get events -n ${K8S_NAMESPACE} \
                    --sort-by='.lastTimestamp' | tail -20 || true
            """
        }
        always {
            echo "Pipeline finished. Build #${BUILD_NUMBER}"
            // Clean up dangling Docker images to save disk space
            sh "docker image prune -f || true"
        }
    }
}
