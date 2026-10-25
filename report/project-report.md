# Project Report: Automated Deployment of a Web Application using CI/CD, Terraform, Azure, and Jenkins

## 1. Abstract
This project demonstrates an automated deployment workflow for a simple web application. GitHub stores the source code, Jenkins validates and packages the application, Terraform defines and provisions the Azure infrastructure, and an Azure Linux virtual machine hosts the website using Nginx.

## 2. Objective
To design and implement a DevOps pipeline that automates infrastructure provisioning and web application deployment on Microsoft Azure using Terraform, GitHub, and Jenkins.

## 3. Tools Used
- Microsoft Azure: cloud infrastructure
- Terraform: Infrastructure as Code
- Jenkins: CI/CD automation
- Git and GitHub: source control
- HTML/CSS: sample web application
- Ubuntu Linux and Nginx: web hosting

## 4. Architecture
Developer commits code to GitHub. Jenkins checks out the repository, validates and packages the HTML file, and—when deployment is enabled and credentials are configured—copies it to the Azure VM over SSH. Terraform provisions the resource group, virtual network, subnet, public IP, network interface, network security group, and VM.

## 5. Methodology
1. Install and verify the required tools.
2. Authenticate to Azure.
3. Define infrastructure in Terraform.
4. Review and apply the Terraform plan.
5. Configure Jenkins and its repository connection.
6. Configure SSH credentials securely.
7. Validate and package the website in Jenkins.
8. Enable deployment after verifying network access.
9. Test the website and automatic pipeline trigger.

## 6. Implementation
The application is located in `app/index.html`. Infrastructure definitions are in `terraform/`. Deployment commands are in `scripts/deploy.sh`, and the pipeline is in `Jenkinsfile`.

## 7. Results and Screenshots
Insert genuine screenshots after completing the implementation:
- Terraform init/validate/plan/apply
- Azure resources in the portal
- Successful Jenkins pipeline
- Website open in a browser using the Azure public IP
- Website updated after a GitHub commit

Do not claim a stage succeeded until it has been tested.

## 8. Observations
Record the actual build status, deployment duration, VM details, and any errors resolved during testing.

## 9. Conclusion
The project demonstrates how version control, pipeline automation, and Infrastructure as Code can work together to deploy a web application to the cloud. Successful completion should be verified through the Jenkins logs and the running website.

## 10. References
- Microsoft Azure documentation
- Terraform documentation
- Jenkins documentation
- GitHub documentation
