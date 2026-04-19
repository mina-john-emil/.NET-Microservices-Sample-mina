1) adds the .NET SDK path to the "Environment Variables" for this specific session.
2) pipeline script
```bash
pipeline {
    agent any

    tools {
        dotnetsdk 'dotnet-sdk'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/mina-john-emil/.NET-Microservices-Sample-mina.git'
            }
        }
        stage('Restore & Build') {
            steps {

                bat 'for /r %%i in (*.sln) do dotnet build "%%i" --configuration Release -m'
            }
        }
    }
}
```
