# Demo of GCP and Terraform - Simple TODO application
Create a 3 tier architecure 
1. Frontend is built with Flutter Web
2. Backend is built with Nodejs Express API
3. Backend is connected to Cloud SQL database 


Script triggers the following process/workflow : 
1. First creates a replica for existing Cloud SQL master database instance - Collects the replica IP
2. Creates the middleware application (Nodejs, Express) - Sets the database replica IP as an environment variable - Collects the IP of this VM
3. Creates the Flutter web instance and passes the Nodejs API VM's IP as environment variable to Flutter Web
# gcp-dr-demo
