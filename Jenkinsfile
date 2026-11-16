pipeline {
    agent { label 'windows-agent' }

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY_NAME = 'tech-challenge-2-app'
        RELEASE_NAME = 'hello-app'
    }

    stages {
        stage('Checkout code') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-tech-challenge-2-read',
                    url: 'https://github.com/dexter210/tech-challenge-2.git'
            }
        }

        stage('Prepare image tag') {
            steps {
                script {
                    env.AWS_ACCOUNT_ID = bat(
                        script: '@aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                    env.ECR_REPO = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY_NAME}"
                    env.IMAGE_TAG = "jenkins-${env.BUILD_NUMBER}-${System.currentTimeMillis()}"

                    echo "Image tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build Docker image') {
            steps {
                bat 'docker build -t "%ECR_REPO%:%IMAGE_TAG%" .'
            }
        }

        stage('Push image to ECR') {
            steps {
                bat '''
                    @echo off
                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REGISTRY%
                    if errorlevel 1 exit /b 1
                    docker push "%ECR_REPO%:%IMAGE_TAG%"
                '''
            }
        }

        stage('Deploy to EKS with Helm') {
            steps {
                bat '''
                    @echo off
                    helm upgrade --install %RELEASE_NAME% .\\helm\\tech-challenge-2 --reuse-values --set-string image.repository=%ECR_REPO% --set-string image.tag=%IMAGE_TAG% --wait --timeout 5m
                    if errorlevel 1 exit /b 1
                    kubectl rollout status deployment/%RELEASE_NAME% --timeout=5m
                '''
            }
        }
    }

    post {
        success {
            echo 'Build, push, and deployment completed successfully.'
        }
        failure {
            echo 'The pipeline failed. Review the stage logs before retrying.'
        }
    }
}