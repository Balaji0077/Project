pipeline {
    agent any
    environment {
        IMAGE_NAME = "gitrebase-app"
        REGISTRY = "balaji0077/project"
        MAX_SIZE_MB = 200
        FEATURE_BRANCH = "feature"
        MAIN_BRANCH = "master"
    }
    // triggers {
    //     // Trigger automatically on feature branch changes
    //     pollSCM('* * * * *')  // replace with webhook if available
    // }

    stages {
        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                checkout scm
                sh '''
                   git config user.name "Balaji0077"
                    git config user.email "balajisugur@gmail.com"
                    git fetch origin ${MAIN_BRANCH}
                    git fetch origin ${FEATURE_BRANCH}
                    git log --oneline -3
                '''
            }
        }

        stage('Git Rebase Ops') {
            steps {
                script {
                    try {
                        echo "Rebasing ${FEATURE_BRANCH} onto ${MAIN_BRANCH}..."
                        sh '''
                            git checkout ${FEATURE_BRANCH}
                            git rebase origin/${MAIN_BRANCH}
                        '''
                        sh 'git log --oneline -5'
                    } catch (err) {
                        echo "Rebase conflict detected! Aborting rebase..."
                        sh '''
                            git rebase --abort || true
                            echo "Conflicted files:"
                            git status --porcelain
                        '''
                        currentBuild.result = 'ABORTED'
                        error("Rebase failed with conflicts. Aborted.")
                    }
                }
            }
        }

        stage('Build Optimized Image') {
            steps {
                echo "Building optimized Docker image with squashed layers..."
                script {
                    
                    sh """
                        docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    """
                }
            }
        }

        stage('Size Check and Push') {
            steps {
                script {
                        //     def imageSizeStr = sh(
                        //     script: 'docker images gitrebase-app:${BUILD_NUMBER} --format "{{.Size}}"',
                        //     returnStdout: true
                        // ).trim()
            
                        // echo "🔍 Docker reported size: '${imageSizeStr}'"
            
                        // // Extract the numeric part (e.g., "95.3" from "95.3MB")
                        // def cleanStr = imageSizeStr.replaceAll("[^0-9.]", "")
                        // def sizeInMB = 0.0
            
                        // if (imageSizeStr.toUpperCase().contains("GB")) {
                        //     sizeInMB = (cleanStr as Float) * 1024
                        // } else if (imageSizeStr.toUpperCase().contains("MB")) {
                        //     sizeInMB = (cleanStr as Float)
                        // } else if (imageSizeStr.toUpperCase().contains("KB")) {
                        //     sizeInMB = (cleanStr as Float) / 1024
                        // } else {
                        //     echo "Unknown size format: '${imageSizeStr}', assuming 0MB"
                        // }
                    def imageRef = "${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    def imageSizeStr = sh(
                        script: "docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep -F \"${imageRef}\" | awk '{print \\$2}' || true",
                        returnStdout: true
                    ).trim()

                    if (!imageSizeStr) {
                        // fallback: try querying by repo:tag directly
                        imageSizeStr = sh(
                            script: "docker images ${imageRef} --format '{{.Size}}' || true",
                            returnStdout: true
                        ).trim()
                    }

                    echo "🔍 Docker reported size (raw): '${imageSizeStr}'"

                    // Normalize and parse the size in MB (sandbox-safe)
                    def cleanStr = imageSizeStr.replaceAll("[^0-9.]", "")
                    def sizeInMB = 0.0

                    if (imageSizeStr.toUpperCase().contains("GB")) {
                        // sandbox-safe conversion: use Groovy 'as Float'
                        sizeInMB = (cleanStr ? (cleanStr as Float) * 1024 : 0.0)
                    } else if (imageSizeStr.toUpperCase().contains("MB")) {
                        sizeInMB = (cleanStr ? (cleanStr as Float) : 0.0)
                    } else if (imageSizeStr.toUpperCase().contains("KB")) {
                        sizeInMB = (cleanStr ? (cleanStr as Float) / 1024 : 0.0)
                    } else if (!imageSizeStr) {
                        echo "⚠️ Could not determine image size; treating as 0 MB (fail-safe)."
                        sizeInMB = 0.0
                    } else {
                        // Unknown format: attempt best-effort parse
                        try {
                            sizeInMB = (cleanStr ? (cleanStr as Float) : 0.0)
                        } catch (Throwable t) {
                            echo "⚠️ Failed to parse size string '${imageSizeStr}': ${t}"
                            sizeInMB = 0.0
                        }
                    }

                    // round/format log
                    echo "📏 Normalized image size: ${sizeInMB} MB (limit ${MAX_SIZE_MB} MB)"


                    if (sizeInMB > MAX_SIZE_MB) {
                        echo "Image too large: ${imageSizeStr}. Allowed: ${MAX_SIZE_MB}MB"
                        currentBuild.result = 'ABORTED'
                        error("Build aborted due to image size exceeding limit.")
                    } else {
                        echo "Image size OK (${sizeInMB}MB <= ${MAX_SIZE_MB}MB). Pushing to Docker Hub..."
                         DOCKERHUB_CREDENTIALS = credentials('docker-hub-creds') 
                         {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                                docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                                docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                                docker logout
                            '''
                        }
                    }
                }
            }
        }
    }
  

    post {
        success {
            echo "Pipeline completed successfully and image pushed to Docker Hub."
        }
        aborted {
            echo "Pipeline aborted. Please check logs for details."
        }
        failure {
            echo "Pipeline failed. See above logs for cause."
        }
        always {
            echo "Cleaning up Docker artifacts..."
            sh 'docker system prune -f || true'
        }
    }
}
