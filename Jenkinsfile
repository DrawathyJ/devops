pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Website') {
            steps {
                script {
                    if (!fileExists('app/index.html')) {
                        error('app/index.html was not found')
                    }
                }
                sh 'grep -qi "<html" app/index.html'
                echo 'Website HTML validation passed.'
            }
        }

        stage('Package') {
            steps {
                sh 'mkdir -p build && cp app/index.html build/index.html'
                archiveArtifacts artifacts: 'build/index.html', fingerprint: true
            }
        }

        stage('Deploy to Azure VM') {
            when {
                expression { return env.DEPLOY_TO_AZURE == 'true' }
            }
            steps {
                echo 'Deployment is enabled. Configure SSH credentials and the deploy target before enabling this stage.'
                withCredentials([sshUserPrivateKey(credentialsId: 'azure-vm-ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER')]) {
                    sh '''
                      set -eu
                      test -n "$AZURE_VM_HOST"
                      scp -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" app/index.html "$SSH_USER@$AZURE_VM_HOST:/tmp/index.html"
                      scp -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" scripts/deploy.sh "$SSH_USER@$AZURE_VM_HOST:/tmp/deploy.sh"
                      ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY" "$SSH_USER@$AZURE_VM_HOST" 'chmod +x /tmp/deploy.sh && /tmp/deploy.sh'
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review the stage logs.'
        }
    }
}
