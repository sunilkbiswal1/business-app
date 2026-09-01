pipeline {

    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME          = 'businessproject'
        SONAR_PROJECT_KEY = 'businessproject'
        NEXUS_URL         = 'http://192.168.1.11:8081'
        DOCKER_REGISTRY   = ''
        IMAGE_NAME        = 'business-project'
        IMAGE_TAG         = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {

            steps {
                echo '=========== GIT CHECKOUT ============'
                checkout scm
            }
        }

        stage('BUild & Test') {

            steps {
                echo '============= MAVEN BUILD & TEST =============='
                sh 'mvn clean compile test'
            }
        }

        stage('package') {
            steps {
                echo "============ PACKAGE ============"
                sh 'mvn package -DskipTests'
            }
        }

        stage('Static Code Analysis') {
            steps {
                echo "==================== SONARQUBE  ANALYSIS =================="
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        mvn -B sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY}
                    '''
                }
            }
        }

        stage('quality Gate') {
            steps {
                echo "=============== SoNARQUBE QUALITYGATE ================"

                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Publish Artifact to  Nexus') {
            steps {
                echo "================== PUBLISH JAR TO NEXUS =============="
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-credentials',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    
                    sh '''
                      set +x

                        GROUP_ID=$(mvn help:evaluate \
                            -Dexpression=project.groupId \
                            -q \
                            -DforceStdout)

                        ARTIFACT_ID=$(mvn help:evaluate \
                            -Dexpression=project.artifactId \
                            -q \
                            -DforceStdout)

                        VERSION=$(mvn help:evaluate \
                            -Dexpression=project.version \
                            -q \
                            -DforceStdout)

                        JAR_FILE=$(find target \
                            -maxdepth 1 \
                            -type f \
                            -name "*.jar" \
                            ! -name "*.original" \
                            | head -1)


                        echo "Group ID    : $GROUP_ID"
                        echo "Artifact ID : $ARTIFACT_ID"
                        echo "Version     : $VERSION"
                        echo "Artifact    : $JAR_FILE"


                        if [ -z "$JAR_FILE" ]; then

                            echo "ERROR: JAR file not found"

                            exit 1
                        fi


                        case "$VERSION" in

                            *-SNAPSHOT)
                                NEXUS_REPO="maven-snapshots"
                                ;;

                            *)
                                NEXUS_REPO="maven-releases"
                                ;;
                        esac


                        echo "Nexus Repository: $NEXUS_REPO"


                        cat > nexus-settings.xml <<EOF
<settings>
    <servers>

        <server>

            <id>nexus</id>

            <username>${NEXUS_USER}</username>

            <password>${NEXUS_PASSWORD}</password>

        </server>

    </servers>
</settings>
EOF


                        mvn -B \
                            -s nexus-settings.xml \
                            deploy:deploy-file \
                            -DgroupId="$GROUP_ID" \
                            -DartifactId="$ARTIFACT_ID" \
                            -Dversion="$VERSION" \
                            -Dpackaging=jar \
                            -Dfile="$JAR_FILE" \
                            -DpomFile=pom.xml \
                            -DrepositoryId=nexus \
                            -Durl="${NEXUS_URL}/repository/${NEXUS_REPO}/"  

                            rm -f nexus-settings.xml
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "============== DOCKER BUILD========"

                sh '''
                    docker build -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} . 
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                echo "================ Trivy Scan ===================="

                sh '''
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --ignore-unfixed \
                        ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Docker Push') {
            steps {
                echo "================= PUSHING IMAGE TO DOCKERHUB ==============="
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                        set +X

                        echo $DOCKER_PASSWORD | \
                        docker login ${DOCKER_REGISTRY} \
                        -u "$DOCKER_USER" \
                        --password-stdin

                        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

     post {
        always {
            archiveArtifacts artifacts: 'target/*.jar, trivy-*-report.txt', allowEmptyArchive: true
            junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
        }
        failure {
            echo "Pipeline failed. Check the failed stage logs above."
        }
        success {
            echo "Pipeline completed successfully. Image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
