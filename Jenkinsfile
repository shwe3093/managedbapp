pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building'
		sh '''#!/bin/bash
			sudo -i -u ec2-user aws ecr get-login-password --region us-west-2 | sudo docker login --username AWS --password-stdin ${account_id}.dkr.ecr.us-west-2.amazonaws.com/managedb-registry
			sudo -i -u ec2-user aws ssm get-parameter --name userinfo_admin_password --region us-west-2 --with-decryption | jq '."Parameter"."Value"'>> userinfo_admin_password.txt
			export userinfo_admin_password=$(cat userinfo_admin_password.txt)
			sudo -i -u ec2-user aws ssm get-parameter --name rds_uri_code --region us-west-2 --with-decryption | jq '."Parameter"."Value"'>> rds_uri_code.txt
			export rds_uri_code=$(cat rds_uri_code.txt)
			sudo export label="$(date +"%a%m%d%H%M")"
			sudo docker build --tag managedb-registry:$label
			sudo docker tag managedb-registry:$label ${account_id}.dkr.ecr.us-west-2.amazonaws.com/managedb-registry:$label
			sudo docker push ${account_id}.dkr.ecr.us-west-2.amazonaws.com/managedb-registry:$label 		
		'''
            }
        }
    }
}
