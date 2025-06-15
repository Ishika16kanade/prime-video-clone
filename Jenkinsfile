pipeline{
    agent any
    tools{
        jdk 'jdk'
        nodejs 'node22'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/Aseemakram19/amazon-prime-video-kubernetes.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('SonarQube') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=amazon-prime-video \
                    -Dsonar.projectKey=amazon-prime-video '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t amazon-prime-video ."
                       sh "docker tag amazon-prime-video supersection/amazon-prime-video:latest "
                       sh "docker push supersection/amazon-prime-video:latest "
                    }
                }
            }
        }
		stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview supersection/amazon-prime-video:latest'
                       sh 'docker-scout cves supersection/amazon-prime-video:latest'
                       sh 'docker-scout recommendations supersection/amazon-prime-video:latest'
                   }
                }
            }
        }

        stage("TRIVY-docker-images"){
            steps{
                sh "trivy image supersection/amazon-prime-video:latest > trivyimage.txt"
            }
        }
        stage('App Deploy to Docker container'){
            steps{
                sh '''
                    docker rm -f amazon-prime-video || true
                    docker run -d --name amazon-prime-video -p 3000:3000 supersection/amazon-prime-video:latest
                '''
            }
        }

    }
    post {
        always {
            script {
                try {
                    def buildStatus = currentBuild.currentResult
                    def buildUser = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: 'Github User'

                    emailext (
                        subject: "Pipeline ${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <p>This is a Jenkins amazon-prime-video CICD pipeline status.</p>
                            <p><b>Project:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                            <p><b>Build Status:</b> ${buildStatus}</p>
                            <p><b>Started By:</b> ${buildUser}</p>
                            <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                        """,
                        to: 'soumosarkar.official@gmail.com',
                        from: 'soumosarkar.official@gmail.com',
                        replyTo: 'soumosarkar.official@gmail.com',
                        mimeType: 'text/html',
                        attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
                    )
                } catch (err) {
                    echo "Email sending failed: ${err}"
                }
            }
        }
    }

}
