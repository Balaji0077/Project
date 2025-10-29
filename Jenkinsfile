pipeline {
    agent any
    environment {
        IMAGE_NAME = "gitrebase-app"
        REGISTRY = "balaji0077/project"
        MAX_SIZE_MB = 100
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
                        docker build --squash -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    """
                }
            }
        }

        stage('Size Check and Push') {
            steps {
                script {
                    def imageSize = sh(
                        script: "docker images ${IMAGE_NAME}:${BUILD_NUMBER} --format '{{.Size}}'",
                        returnStdout: true
                    ).trim()

                    echo "Built Image Size: ${imageSize}"

                    // Extract numeric part and convert to MB
                    def sizeValue = imageSize.replaceAll('[^0-9.]', '').toFloat()
                    def isGB = imageSize.toLowerCase().contains('gb')
                    if (isGB) {
                        sizeValue = sizeValue * 1024
                    }

                    if (sizeValue > MAX_SIZE_MB) {
                        echo "Image too large: ${imageSize}. Allowed: ${MAX_SIZE_MB}MB"
                        currentBuild.result = 'ABORTED'
                        error("Build aborted due to image size exceeding limit.")
                    } else {
                        echo "Image size OK (${sizeValue}MB <= ${MAX_SIZE_MB}MB). Pushing to Docker Hub..."
                        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds',
                                                          usernameVariable: 'balaji0077',
                                                          passwordVariable: 'dckr_pat_p_aEoLw-CkHKuIVaK4Qb1NORKlw')]) {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
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
