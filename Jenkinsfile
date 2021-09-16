pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building'
		sh '''#!/bin/bash
			aws ecr get-login-password --region us-west-2 | sudo docker login --username AWS --password-stdin ${account_id}.dkr.ecr.us-west-2.amazonaws.com/managedb-registry	
		'''
            }
        }
    }
}
