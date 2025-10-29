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
                // script {
                //     def imageSizeStr = sh(
                //         script: 'docker images gitrebase-app:${BUILD_NUMBER} --format "{{.Size}}"',
                //         returnStdout: true
                //     ).trim()
                //
                //     echo "🔍 Docker reported size: '${imageSizeStr}'"
                //
                //     // Extract the numeric part (e.g., "95.3" from "95.3MB")
                //     def cleanStr = imageSizeStr.replaceAll("[^0-9.]", "")
                //     def sizeInMB = 0.0
                //
                //     if (imageSizeStr.toUpperCase().contains("GB")) {
                //         sizeInMB = (cleanStr as Float) * 1024
                //     } else if (imageSizeStr.toUpperCase().contains("MB")) {
                //         sizeInMB = (cleanStr as Float)
                //     } else if (imageSizeStr.toUpperCase().contains("KB")) {
                //         sizeInMB = (cleanStr as Float) / 1024
                //     } else {
                //         echo "Unknown size format: '${imageSizeStr}', assuming 0MB"
                //     }
                //
                //     if (sizeInMB > MAX_SIZE_MB) {
                //         echo "Image too large: ${imageSizeStr}. Allowed: ${MAX_SIZE_MB}MB"
                //         currentBuild.result = 'ABORTED'
                //         error("Build aborted due to image size exceeding limit.")
                //     }
                // }

                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DH_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${DH_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                        docker logout
                    '''
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
