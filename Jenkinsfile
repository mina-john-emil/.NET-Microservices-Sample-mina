pipeline {
    agent any

    environment {
        REGISTRY      = "microservices"
        GIT_REPO      = "https://github.com/mina-john-emil/.NET-Microservices-Sample-mina.git"
        VM_IP         = "192.168.150.135"
        IMAGE_TAG     = "${BUILD_NUMBER}"
        // FIX #3: define namespace as a plain string here so it is
        // accessible everywhere including post{} blocks.
        // The root cause: environment{} vars ARE available in post{},
        // BUT only if the pipeline reached the 'agent' allocation.
        // When checkout fails before node allocation completes,
        // Groovy resolves them as bare variables and throws
        // MissingPropertyException. Using a local def inside node{}
        // avoids that completely — see post{} section below.
        K8S_NS        = "default"
        STORAGE_DRIVER = "overlay2"
    }

    stages {

        // ── Stage 1: Checkout ─────────────────────────────────
        // FIX #1 — GitHub port 443 Connection Refused
        // Root cause: your Jenkins VM's firewall blocks OUTBOUND
        // HTTPS to github.com. Two fixes applied here:
        //   A) Configure git to use a longer timeout
        //   B) Add a connectivity check BEFORE git clone so you
        //      get a clear error message instead of a cryptic
        //      git exception.
        // You ALSO need to run this on the server (one time only):
        //   firewall-cmd --permanent --add-service=https
        //   firewall-cmd --reload
        // OR if behind a corporate proxy, set in Jenkins:
        //   Manage Jenkins → System → HTTP Proxy Configuration
        stage('Checkout') {
            steps {
                echo "Checking network connectivity to GitHub..."

                // Test outbound HTTPS before attempting git clone.
                // If this fails, the error message tells you exactly
                // what to fix (firewall or proxy).
                sh '''
                    curl -s --max-time 10 https://github.com > /dev/null \
                        && echo "✅ GitHub is reachable" \
                        || { echo "❌ Cannot reach github.com — check firewall/proxy"; exit 1; }
                '''

                echo "Cloning repo from GitHub..."
                // git timeout extended to 120s for slow connections
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: "${GIT_REPO}"]],
                    extensions: [
                        [$class: 'CloneOption',
                         timeout: 120,       // seconds — default is 10
                         shallow: true,      // faster: only latest commit
                         depth: 1]
                    ]
                ])
                echo "Checkout done ✅"
            }
        }

        // ── Stage 2: Build Docker Images ──────────────────────
        stage('Build Images') {
            steps {
                echo "Building all Docker images..."
                script {
                    def services = [
                        [name: 'orderservice',
                         dockerfile: 'src/Services/Orders/OrderService/Dockerfile'],
                        [name: 'basketservice',
                         dockerfile: 'src/Services/Baskets/BasketService/Dockerfile'],
                        [name: 'discountservice',
                         dockerfile: 'src/Services/Discounts/DiscountService/Dockerfile'],
                        [name: 'productservice',
                         dockerfile: 'src/Services/Products/ProductService/Dockerfile'],
                        [name: 'paymentserviceendpoint',
                         dockerfile: 'src/Services/Payments/Presentation/PaymentService.EndPoint/Dockerfile'],
                        [name: 'identityservice',
                         dockerfile: 'src/Identity/IdentityService/Dockerfile'],
                        [name: 'apigatewayadmin',
                         dockerfile: 'src/ApiGateways/ApiGateway.Admin/Dockerfile'],
                        [name: 'apigatewayforweb',
                         dockerfile: 'src/ApiGateways/ApiGatewayForWeb/Dockerfile'],
                        [name: 'microservicesadminfrontend',
                         dockerfile: 'src/Web/Microservices.Admin.Frontend/Dockerfile'],
                        [name: 'microserviceswebfrontend',
                         dockerfile: 'src/Web/Microservices.Web.Frontend/Microservices.Web.Frontend/Dockerfile'],
                    ]

                    services.each { svc ->
                        echo "Building ${svc.name}..."
                        sh "docker build -t ${REGISTRY}/${svc.name}:${IMAGE_TAG} -t ${REGISTRY}/${svc.name}:latest -f ${svc.dockerfile} ."
                        echo "${svc.name} built ✅"
                    }
                }
            }
        }

        // ── Stage 3: Run Tests ────────────────────────────────
        stage('Test') {
            steps {
                echo "Running tests..."
                script {
                    def testProjects = [
                        'src/Services/Products/tests/ProductServiceComponent.Test/ProductService.ComponentTests.csproj',
                    ]

                    testProjects.each { proj ->
                        def exists = sh(
                            script: "[ -f '${proj}' ] && echo yes || echo no",
                            returnStdout: true
                        ).trim()

                        if (exists == 'yes') {
                            echo "Running: ${proj}"
                            sh "dotnet test '${proj}' --verbosity normal"
                        } else {
                            echo "Skipping (not found): ${proj}"
                        }
                    }
                }
                echo "Tests done ✅"
            }
        }
        stage('Initialize KinD Cluster') {
            steps {
                sh '''
                    if ! kind get clusters | grep -q "dev-cluster"; then
                        echo "Creating KinD cluster..."
                        kind create cluster --name dev-cluster --config kind-config.yaml --wait 60s
                    else
                        echo "KinD cluster already exists ✅"
                    fi
                    # Always export kubeconfig so kubectl/helm can reach the cluster
                    kind export kubeconfig --name dev-cluster --kubeconfig /var/lib/jenkins/.kube/config
                    echo "Kubeconfig exported ✅"
                    kubectl get nodes
                '''
                
            }
        }


        // ── Stage 4: Load Images into Kind ───────────────────
        stage('Load Images to Kind') {
            steps {
                echo "Loading images into kind cluster..."
                script {
                    def images = [
                        'orderservice', 'basketservice', 'discountservice',
                        'productservice', 'paymentserviceendpoint',
                        'identityservice', 'apigatewayadmin', 'apigatewayforweb',
                        'microservicesadminfrontend', 'microserviceswebfrontend',
                    ]

                    images.each { img ->
                        echo "Loading ${img}..."
                        sh """
                            kind load docker-image \\
                                --name dev-cluster \\
                                ${REGISTRY}/${img}:${IMAGE_TAG}
                        """
                    }
                }
                echo "All images loaded ✅"
            }
        }

        // ── Stage 0: Initialize Environment ──────────────────

        
        // ── Stage 5: Deploy with Helm ─────────────────────────
        stage('Deploy') {
            steps {
                echo "Deploying to Kubernetes via Helm..."
                sh """
                    helm upgrade --install microservices helm/microservices/ \\
                        --namespace ${K8S_NS} \\
                        --set global.imageTag=${IMAGE_TAG} \\
                        --set global.vmIP=${VM_IP} \\
                        --wait \\
                        --timeout 5m
                """
                echo "Deployment done ✅"
            }
        }

        // ── Stage 6: Verify ───────────────────────────────────
        stage('Verify') {
            steps {
                echo "Verifying all pods are running..."
                sh """
                    echo "=== Pod Status ==="
                    kubectl get pods -n ${K8S_NS}

                    echo "=== Services ==="
                    kubectl get services -n ${K8S_NS}

                    echo "=== Helm Release ==="
                    helm status microservices -n ${K8S_NS}

                    NOT_RUNNING=\$(kubectl get pods -n ${K8S_NS} \\
                        --field-selector=status.phase!=Running \\
                        --no-headers 2>/dev/null | grep -v "Completed" | wc -l)

                    if [ "\$NOT_RUNNING" -gt "0" ]; then
                        echo "ERROR: Some pods are not running!"
                        kubectl get pods -n ${K8S_NS}
                        exit 1
                    fi

                    echo "All pods running ✅"
                """
            }
        }
    }

    // ── post{} — FIX #2 + FIX #3 ─────────────────────────────
    // FIX #2: sh steps in post{} MUST be wrapped in node{} because
    //   post{} runs outside the main agent allocation context.
    //   Without node{}, Jenkins throws:
    //   "MissingContextVariableException: Required context class
    //    hudson.FilePath is missing"
    //
    // FIX #3: Use env.K8S_NS instead of bare K8S_NAMESPACE.
    //   When checkout fails early, bare environment variable names
    //   are not resolved by Groovy — they appear as undefined
    //   class properties and throw MissingPropertyException.
    //   Prefixing with "env." forces Jenkins to resolve from the
    //   environment map which always works.
    post {

        success {
            echo """
╔══════════════════════════════════════╗
║   DEPLOYMENT SUCCESSFUL ✅            ║
║   Build:    #${BUILD_NUMBER}         ║
║   Web:      http://${VM_IP}:31328    ║
║   Admin:    http://${VM_IP}:31298    ║
║   Identity: http://${VM_IP}:31720    ║
║   RabbitMQ: http://${VM_IP}:31672    ║
╚══════════════════════════════════════╝
            """
        }

        failure {
            // FIX #2: wrapped in node{} so sh is allowed here
            // FIX #3: env.K8S_NS instead of bare K8S_NAMESPACE
            node('') {
                echo "❌ Pipeline FAILED — showing debug info..."
                sh """
                    echo "=== Failed or Pending Pods ==="
                    kubectl get pods -n ${env.K8S_NS} \
                        --no-headers 2>/dev/null | grep -v Running || true

                    echo "=== Recent K8s Events ==="
                    kubectl get events -n ${env.K8S_NS} \
                        --sort-by='.lastTimestamp' 2>/dev/null | tail -20 || true
                """
            }
        }

        always {
            // FIX #2: wrapped in node{} so sh is allowed here
            node('') {
                echo "Pipeline finished. Build #${BUILD_NUMBER}"
                sh "docker image prune -f || true"
            }
        }
    }
}
