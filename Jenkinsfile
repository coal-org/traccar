pipeline {
    agent any

    environment {
        // Definir variables de entorno, como GRADLE_HOME si es necesario
        GRADLE_HOME = '/usr/bin/gradle'
    }

    stages {
        stage('Checkout') {
            steps {
                // Obtener código fuente desde el control de versiones
                checkout scm
            }
        }

        stage('Build') {
            steps {
                // Compilar el proyecto usando Gradle
                 echo 'Build...'
                sh "./gradlew assemble"
            }
        }

        stage('Tests') {
            steps {
                // Ejecutar pruebas (puedes modificar esto según sea necesario)
                 echo 'Test...'
                sh "./gradlew test"
            }
        }

        stage('Archive') {
            steps {
                // Archivar artefactos como el JAR compilado
                echo 'Artifacts...'
                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                
            }
        }

        stage('Deploy') {
            steps {
                // Mover los archivos compilados a la ruta correcta
                echo 'Deploy backend...'
                sh  '''
                    sudo cp -r -f /var/lib/jenkins/workspace/traccar-prod/target/* /opt/traccar/
                    sudo cp -r -f /var/lib/jenkins/workspace/traccar-prod/debug.xml /opt/traccar/conf/
                    sudo systemctl restart traccar
                '''
            }
        }
    }

    post {
        // Definir acciones post-ejecución como limpieza, notificaciones, etc.
        always {
            // Ejecutar siempre después de las etapas
        }

        success {
            // Ejecutar solo si el pipeline ha sido exitoso
        }

        failure {
            // Ejecutar solo si el pipeline ha fallado
        }
    }
}
