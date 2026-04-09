pipeline {

    agent {
        docker {
            image 'node:20-bullseye'
            args '-u root:root'
        }
    }

    environment {
        DOCKERHUB_CREDENTIALS = 'DOCKER_HUB_PASS'
        GITHUB_CREDENTIALS    = 'github-creds'
        KUBECONFIG_CRED       = 'config'
        BRANCH = "${env.BRANCH_NAME ?: params.BRANCH ?: 'master'}"

        IMAGE = "horacio1986/jenkins_devops_projectapi"
    }

    parameters {
    string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to deploy')
    }

    stages {

        stage('Checkout') {
            steps {    
                echo "📥 Starting Checkout stage for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/master"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/SergesHorace1986/Jenkins_devops_project.git',
                        credentialsId: "${GITHUB_CREDENTIALS}"
                    ]]
                ])
            }
        }

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Build Application') {
            steps {
                echo "🛠 Building application for branch ${env.BRANCH}"
                    sh """
                        npm install
                        npm run build
                    """
            }
        }

        stage('Test Application') {
            steps {
                echo "🧪 Running tests for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                    sh """
                        npm test
                    """
            }
        }

        
        stage('Build Docker Images') {
            
            steps {
                echo "🔧 Building image"
                    sh """
                        docker build -t ${IMAGE}:${env.BRANCH}-${env.BUILD_NUMBER} .
                        """
            }
            
        }

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
                      docker push ${IMAGE}:${env.BRANCH}-${env.BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy') {
            steps {                
                echo "🚢 Starting *Helm Deployment* for branch ${env.BRANCH}"

                withCredentials([file(credentialsId: "${KUBECONFIG_CRED}", variable: 'config')]) {
                    script {
                        // def helmFlags = "--atomic --timeout 5m0s"

                        if (env.BRANCH == "dev" || env.BRANCH == "master" || env.BRANCH.startsWith("feature/")) {
                            sh """
                              export KUBECONFIG=$config
                              helm upgrade --install  fastapi-dev ./fastapi \
                                -n dev \
                                -f fastapi/values-dev.yaml \
                                --set jenkins_devops_projectapi.image.tag=main-13 \
                                --timeout 15m0s
                            """
                        }

                        if (env.BRANCH == "master") {
                            timeout(time: 20, unit: 'MINUTES') {
                                input message: "Deploy to PRODUCTION?"
                            }
                            sh """
                              export KUBECONFIG=$config
                              helm upgrade --install fastapi-prod ./fastapi \
                                -n prod \
                                -f fastapi/values-prod.yaml \
                                --set jenkins_devops_projectapi.image.tag=main-13 \
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
