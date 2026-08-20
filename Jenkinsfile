#!/usr/bin/env groovy

// gitlab source of the shared lib, same as jenkins_pipeline_terraform_ec2_dockerhub_java_maven_app_shared_groovy_lib
library identifier: '12-tf-java-maven-app-learn-shared-lib@main', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'git@gitlab.com:devops-bt/12-tf-java-maven-app-learn-shared-lib.git',
    credentialsId: 'gitlab-jenkins-ssh-key'
    ]
)

// @Library('09-aws-java-maven-app-jenkins-shared-lib') _

pipeline {
    agent any
    tools {
        maven 'maven3916'
    }
    environment {
        BUILD_NAME = 'pandabyxanda/jenkins_pipeline_terraform_ec2_dockerhub_java_maven_app:jm'
    }
    stages {
        stage('build app') {
            steps {
                echo 'building application jar...'
                buildJar()
            }
        }

        stage('version') {
                    steps {
                        script {
                            version = incrementVersion()
                            env.IMAGE_NAME = "${BUILD_NAME}-${version}"
                            sh "echo env.IMAGE_NAME=${env.IMAGE_NAME}"
                        }
                    }
        }

        stage('build image') {
            steps {
                script {
                    echo 'building the docker image...'
                    buildImage(env.IMAGE_NAME)
                    dockerLogin()
                    dockerPush(env.IMAGE_NAME)
                }
            }
        }

        stage("provision infra") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                TF_VAR_env_prefix = 'test5'
                TF_VAR_key_name = "id_ed25519_aws_jenkins_tf"
            }
            steps {
                script {
                    echo "provisioning infra with terraform..."
                    dir ('terraform') {
                        sh 'terraform init'
                        sh 'terraform apply --auto-approve'

                        EC2_PUBLIC_IP = sh(script: "terraform output ec2_public_ip",
                        returnStdout: true).trim()

                }
            }
            }
        }

        stage("deploy") {
            environment {
                DOCKER_CREDS = credentials('jenkins-dockerhub-personal-access-token')
            }
            steps {
                script {
                    echo "waiting for ec2Instance"
                    sleep(time: 120, unit: "SECONDS")
                    echo "EC2_PUBLIC_IP got from terraform: ${EC2_PUBLIC_IP}"

                    echo "deploying docker image ${IMAGE_NAME}"
                    def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                    def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"
                    sshagent(["jenkins_aws_tf_key"]) {
                        sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                        sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }
                }
            }
        }

        stage("commit new version") {
            steps {
                script {
                    commitVersion(env.IMAGE_NAME)
                }
            }
        }
    }
}
