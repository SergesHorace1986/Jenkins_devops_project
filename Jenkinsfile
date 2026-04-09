pipeline {

    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()    
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to deploy')
    }

    environment {
        DOCKERHUB_CREDENTIALS = 'DOCKER_HUB_PASS'
        GITHUB_CREDENTIALS    = 'github-creds'
        KUBECONFIG_CRED       = 'config'
        BRANCH = "${env.BRANCH_NAME ?: params.BRANCH ?: 'master'}"
        IMAGE = "horacio1986/jenkins_devops_projectapi"
    }

    stages {
        
        // ✅ Clean BEFORE checkout
        stage('Clean Workspace') {
            steps {
                sh 'docker run --rm -u root -v "$WORKSPACE:/workspace" node:20-bullseye rm -rf /workspace/node_modules'
                deleteDir()
            }
        }

        // ✅ Clean Docker images to prevent disk space issues
        stage('Cleanup Docker') {
            steps {
                sh 'docker image prune -f'
            }
        }

        // ✅ Proper checkout using credentials
        stage('Checkout') {
            steps { 
                script {   
                    echo "📥 Starting Checkout stage for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${env.BRANCH}"]],
                        userRemoteConfigs: [[
                            url: 'https://github.com/SergesHorace1986/Jenkins_devops_project.git',
                            credentialsId: "${GITHUB_CREDENTIALS}"
                        ]]
                    ])
                }
            }    
        }

        // ✅ Test credentials loading with proper masking
        stage('test Credentials') {
            steps {
                echo "🔍 Testing credentials for DockerHub and GitHub"

                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                      echo "DockerHub Username: $DOCKER_USER"
                      echo "DockerHub Password: ${DOCKER_PASS ? '******' : 'Not Set'}"
                      echo "Dockerhub credentials loaded successfully"
                    """
                }
                withCredentials([usernamePassword(
                    credentialsId: "${GITHUB_CREDENTIALS}",
                    usernameVariable: 'GITHUB_USER',
                    passwordVariable: 'GITHUB_PASS'
                )]) {
                    sh """
                      echo "GitHub Username: $GITHUB_USER"
                      echo "GitHub Password: ${GITHUB_PASS ? '******' : 'Not Set'}"
                        echo "GitHub credentials loaded successfully"
                    """
                }
            }
        }

        // ✅ Build + Test inside Docker
        stage('Build & test Application') {
            steps {
                script {
                    echo "🔧 Building and testing application inside Docker container"

                    sh """
                        echo "Workspace content BEFORE Docker:"
                        pwd && ls -la   
                    """

                    docker.image('node:20-bullseye').inside("-u root") {
                        echo "Running inside Node.js 20 Bullseye container"

                        sh """
                            echo "===== DEBUG INFO ====="
                            whoami && id && pwd && ls -la

                            echo "===== NODE INFO ====="
                            node -v && npm -v
                            
                            echo "===== INSTALL ====="
                            npm install

                            echo "===== TEST ====="
                            npm test 

                            echo "===== CLEANUP ====="
                            rm -rf node_modules
                        """
                    }
                }
            }
        }

        // ✅ Build Docker Image with proper tagging
        stage('Build Docker Images') {
            steps {
                echo "🔧 Building image: ${IMAGE}:${env.BRANCH}-${env.BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE}:${env.BRANCH}-${env.BUILD_NUMBER} ."                    
            }    
        }

        // ✅ Push to DockerHub with proper login and error handling
        stage('Push Images') {
            steps {                
                echo "📤 Pushing Docker images to DockerHub"

                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                      echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                      docker push $IMAGE:$BRANCH-$BUILD_NUMBER
                    """
                }
                sh 'docker logout'
            }
        }
        
        // ✅ Deploy with Helm using proper kubeconfig and error handling
        stage('Deploy') {
            steps {                
                echo "🚢 Starting *Helm Deployment* for branch ${env.BRANCH}"

                withCredentials([file(credentialsId: "${KUBECONFIG_CRED}", variable: 'config')]) {
                    script {
                        // def helmFlags = "--atomic --timeout 5m0s"

                        if (env.BRANCH == "dev" || env.BRANCH == "master" || env.BRANCH.startsWith("feature/")) {
                            sh """
                              export KUBECONFIG=$config
                              helm upgrade --install  fastapi-${env.BRANCH} ./fastapi \
                                -n dev \
                                -f fastapi/values-dev.yaml \
                                --set jenkins_devops_projectapi.image.tag=${env.BRANCH}-${env.BUILD_NUMBER} \
                                --timeout 15m0s
                            """
                        }

                        if (env.BRANCH == "master") {
                            timeout(time: 20, unit: 'MINUTES') {
                                input message: "Deploy to PRODUCTION?"
                            }
                            sh """
                              export KUBECONFIG=$config
                              helm upgrade --install fastapi-${env.BRANCH} ./fastapi \
                                -n prod \
                                -f fastapi/values-prod.yaml \
                                --set jenkins_devops_projectapi.image.tag=${env.BRANCH}-${env.BUILD_NUMBER} \
                                --timeout 15m0s
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            
            echo "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed from branch ${env.BRANCH}"    
        }
        failure {
            
            echo "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} on branch ${env.BRANCH}"  
        }
        always {
            
            echo "Pipeline completed with status: ${currentBuild.currentResult}"
        }
    }
}
