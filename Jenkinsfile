/* import shared library. */


pipeline {
    environment {
        IMAGE_NAME = "ic-webapp"
        APP_CONTAINER_PORT = "8080"
        DOCKERHUB_ID = "henrypoms"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
        ANSIBLE_IMAGE_AGENT = "registry.gitlab.com/robconnolly/docker-ansible:latest"
        
    }
    agent none
    stages {
       stage('Build image') {
           agent any
           steps {
              script {
                sh 'docker build --no-cache -f ./Sources-APP/${DOCKERFILE_NAME} -t ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ./Sources-APP'

              }
           }
       }
       stage('Scan Image with  SNYK') {
            agent any
            environment{
                SNYK_TOKEN = credentials('snyk_token')
            }
            steps {
                script{
                    sh '''
                    echo "Starting Image scan ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ..."
                    echo There is Scan result :
                    SCAN_RESULT=$(docker run --rm -e SNYK_TOKEN=$SNYK_TOKEN -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/app snyk/snyk:docker snyk test --docker $DOCKERHUB_ID/$IMAGE_NAME:$IMAGE_TAG --json ||  if [[ $? -gt "1" ]];then echo -e "Warning, you must see scan result \n" ;  false; elif [[ $? -eq "0" ]]; then   echo "PASS : Nothing to Do"; elif [[ $? -eq "1" ]]; then   echo "Warning, passing with something to do";  else false; fi)
                    echo "Scan ended"
                    '''
                }
            }
       }
       stage('Run container based on builded image') {
          agent any
          steps {
            script {
              sh '''
                  echo "Cleaning existing container if exist"
                  docker ps -a | grep -i $IMAGE_NAME && docker rm -f ${IMAGE_NAME}
                  docker run --name ${IMAGE_NAME} -d -p $APP_EXPOSED_PORT:$APP_CONTAINER_PORT  ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG       
                  sleep 5
              '''
             }
          }
       }
       stage('Test image') {
           agent any
           steps {
              script {
                sh '''
                   curl -I http://${HOST_IP}:${APP_EXPOSED_PORT} | grep -i "200"
                '''
              }
           }
       }
       stage('Clean container') {
          agent any
          steps {
             script {
               sh '''
                   docker stop $IMAGE_NAME
                   docker rm $IMAGE_NAME
               '''
             }
          }
       }

       stage ('Login and Push Image on docker hub') {
          agent any
          steps {
             script {
               sh '''
                   echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_ID --password-stdin
                   docker push ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
               '''
             }
          }
       }
       stage ('Prepare Ansible environment') {
          agent any
          environment {
            VAULT_KEY = credentials('vault_key')
            PRIVATE_KEY = credentials('private_key')
            PUBLIC_KEY = credentials('public_key')
            VAGRANT_PASSWORD = credentials('vagrant_password')
          }          
          steps {
             script {
               sh '''
                  echo "Cleaning workspace before starting"
                  rm -f vault.key id_rsa id_rsa.pub password
                  echo "Generating vault key"
                  echo -e $VAULT_KEY > vault.key
                  echo "Generating private key"
                  cp $PRIVATE_KEY  id_rsa
                  chmod 400 id_rsa vault.key
                  #echo "Generating public key"
                  #echo -e $PUBLIC_KEY > id_rsa.pub
                  #echo -e $VAGRANT_PASSWORD > password
                  echo "Generating host_vars for EC2 servers"
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > Sources-Ansible/host_vars/odoo_server_dev.yml
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > Sources-Ansible/host_vars/ic_webapp_server_dev.yml
                  echo "ansible_host: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" > Sources-Ansible/host_vars/pg_admin_server_dev.yml
                  echo "Generating host_pgadmin_ip and  host_odoo_ip variables"
                  echo "host_odoo_ip: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" >> Sources-Ansible/host_vars/ic_webapp_server_dev.yml
                  echo "host_pgadmin_ip: $(awk '{print $2}' /var/jenkins_home/workspace/ic-webapp/public_ip.txt)" >> Sources-Ansible/host_vars/ic_webapp_server_dev.yml

               '''
             }
          }
        }
        stage('Deploy DEV  env for testing') {
            agent   {     
                        docker { 
                            image 'registry.gitlab.com/robconnolly/docker-ansible:latest'
                        } 
                    }
            stages {
                stage ("Install Ansible role dependencies") {
                    steps {
                        script {
                            sh 'echo launch ansible-galaxy install -r /Sources-Ansible/roles if needed'
                        }
                    }
                }

                stage ("DEV - Ping target hosts") {
                    steps {
                        script {
                            sh '''
                                apt update -y
                                apt install sshpass -y                            
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible dev -m ping  --private-key devops.pem  -o 
                            '''
                        }
                    }
                }

                stage ("Check all playbook syntax") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-lint -x 306 Sources-Ansible/playbooks/* || echo passing linter                                     
                            '''
                        }
                    }
                }

                stage ("DEV - Install Docker on ec2 hosts") {
                    steps {
                        script {

                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/install-docker.yml --vault-password-file vault.key  --private-key devops.pem -l ic_webapp_server_dev
                            '''                                
                        }
                    }
                }

                stage ("DEV - Deploy pgadmin") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-pgadmin.yml --vault-password-file vault.key --private-key devops.pem -l pg_admin_server_dev
                            '''
                        }
                    }
                }

                stage ("DEV - Deploy odoo") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-odoo.yml --vault-password-file vault.key  --private-key devops.pem -l odoo_server_dev
                            '''
                        }
                    }
                }

                stage ("DEV - Deploy ic-webapp") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-ic-webapp.yml --vault-password-file vault.key --private-key devops.pem -l ic_webapp_server_dev
                            '''
                        }
                    }
                }

            }
        }

        stage ("Delete Dev environment") {
            agent { docker { image 'jenkins/jnlp-agent-terraform'  } }
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
                PRIVATE_AWS_KEY = credentials('private_aws_key')
            }
            steps {
                script {       
                    timeout(time: 30, unit: "MINUTES") {
                        input message: "Confirmer vous la suppression de la dev dans AWS ?", ok: 'Yes'
                    } 
                    sh'''
                        cd "./sources/terraform ressources/app"
                        terraform destroy --auto-approve
                        rm -rf sources/ansible-ressources/host_vars/*.dev.yml
                        rm -rf devops.pem
                    '''                            
                }
            }
        }  
        stage ("Deploy in PRODUCTION") {
            /* when { expression { GIT_BRANCH == 'origin/prod'} } */
            agent { docker { image 'registry.gitlab.com/robconnolly/docker-ansible:latest'  } }                     
            stages {
                stage ("PRODUCTION - Ping target hosts") {
                    steps {
                        script {
                            sh '''
                                apt update -y
                                apt install sshpass -y                            
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible prod -m ping  -o
                            '''
                        }
                    }
                }                                                       
                stage ("PRODUCTION - Install Docker on all hosts") {
                    steps {
                        script {
                            timeout(time: 30, unit: "MINUTES") {
                                input message: "Etes vous certains de vouloir cette MEP ?", ok: 'Yes'
                            }                            

                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/install-docker.yml --vault-password-file vault.key  -l odoo_server,pg_admin_server
                            '''                                
                        }
                    }
                }

                stage ("PRODUCTION - Deploy pgadmin") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-pgadmin.yml --vault-password-file vault.key  -l pg_admin
                            '''
                        }
                    }
                }
                stage ("PRODUCTION - Deploy odoo") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-odoo.yml --vault-password-file vault.key  -l odoo
                            '''
                        }
                    }
                }

                stage ("PRODUCTION - Deploy ic-webapp") {
                    steps {
                        script {
                            sh '''
                                export ANSIBLE_CONFIG=$(pwd)/Sources-Ansible/ansible.cfg
                                ansible-playbook Sources-Ansible/playbooks/deploy-ic-webapp.yml --vault-password-file vault.key  -l ic_webapp

                            '''
                        }
                    }
                }
            }
        } 
    }  

    post {
        always {
            script {
                /*sh '''
                    echo "Manually Cleaning workspace after starting"
                    rm -f vault.key id_rsa id_rsa.pub password devops.pem public_ip.txt
                ''' */
                slackNotifier currentBuild.result
            }
        }
    }    
        
        
        
        
        
    }
}
        
