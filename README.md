# Deployment of Amazon Prime Video Clone App

Production-grade DevSecOps project - a modern application delivered with a robust DevSecOps CI/CD pipeline on Amazon EKS, secured via Cloudflare SSL, and monitored using Prometheus-Grafana.

---

## Setup an EC2 Instance

1. Launch a new EC2 Instance (named `APP_SERVER`)
2. **AMI:** Ubuntu Server 24.04 LTS
3. **Instance type:** `t2.large`
4. Select a key pain (for SSH login)
5. Network settings:
    - Provide name (`primevideo-sg`) & create new **security group** on default VPC
    - Allow SSH traffic from Anywhere
6. **EBS volume:** 20 GB

### Edit Inbound Rules of that Security Group

Add the following ports for now (if needed later, we can add):

1. SSH → 22
2. Jenkins → 8080
3. HTTP → 80
4. HTTPS → 443
5. SonarQube → 9000
6. SMTP → 587
7. SMTPS → 465
8. Node.js → 3000

### Login to your Instance via SSH

Use your private key to login to the `APP_SERVER`. Then follow the below steps:

```bash
sudo apt update -y

git clone https://github.com/soumosarkar297/devops-tools-installer-scripts.git
cd devops-tools-installer-scripts
chmod +x *.sh
```

### Setup Jenkins

```bash
sh jenkins.sh
jenkins --version
systemctl status jenkins
# Access Jenkins on: <instance-public-ip>:8080

# Get the Jenkins administrator password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Install suggested plugins in Jenkins setup
```

1. Create a new user to login
2. Add the following plugins to your Jenkins:
    - Eclipse Temurin installer
    - SonarQube Scanner
    - Sonar Quality Gates
    - Pipeline: Stage View
    - NodeJS
    - Docker
    - Docker Commons
    - Docker Pipeline
    - Docker API
    - Kubernetes
    - Kubernetes Client API
    - Kubernetes Credentials
    - Kubernetes CLI
    - Kubernetes Credentials Provider
    - Kubernetes :: Pipeline :: DevOps Steps
    - Blue Ocean

3. Restart Jenkins when all the plugins are installed

### Setup SonarQube as a Docker Container

```bash
sh docker.sh
docker --version
systemctl status docker

# Run SonarQube container in detached mode with port mapping
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

docker images
docker ps
```

1. Access SonarQube on: `http://<instance-public-ip>:9000`
2. Povide default username & password as `admin`
3. Set new password. You will be on the dashboard page
4. Go to Administration > Security > Users > Tokens
5. Provide token name (`jenkins-amazonprimevideo`) and Generate
6. Copy the created token: `squ_91d5919bcf70b7a2482391ff662bee2f9cd417c8`

### Configure Webhook in SonarQube

1. Administration > Configuration > Webhooks
2. Create Webhook
    - **Name:** jenkins
    - **URL:** `http://<instance-public-ip>:8080/sonarqube-webhook/`
    - Create

### Setup Terraform & AWS CLI

```bash
sh terraform.sh
terraform --version

sh awscli.sh
aws --version
```

### Setuo kubectl & eksctl

```bash
sh kubectl.sh

sh eksctl.sh
```

### Setup Trivy

```bash
sh trivy.sh
```

---

## Configure SonarQube on Jenkins

### Add SonarQube token as Jenkins Credentials

1. Dashboard > Manage Jenkins > Credentials
2. System > (global) > Add credentials
3. New credentials:
    - **Kind:** Secret text
    - **Scope:** Global
    - **Secret:** Paste your token from SonarQube
    - **ID:** `Sonar-token`
    - Create

### Add SonarQube server on Jenkins System

1. Dashboard > Manage Jenkins > System > Scroll down to "SonarQube servers"
2. Add SonarQube:
    - **Name:** SonarQube
    - **Server URL:** `http://<instance-public-ip>:9090`
    - **Server authentication token:** `Sonar-token`
3. Apply and Save

### Add SonarQube Scanner Tool in Jenkins

1. Dashboard > Manage Jenkins > Tools
2. Scroll down to "SonarQube Scanner installations"
3. Add SonarQube Scanner
    - **Name:** sonar-scanner
    - Install automatically
4. Apply and Save

---

## Configure Docker in Jenkins

### Add Docker Credentials to Jenkins System

Login to your [Docker Hub](https://hub.docker.com/) Account. Create a Personal Access Token (PAT).

Follow the below steps on Jenkins:

1. Dashboard > Manage Jenkins > Credentials > System > Global credentials (unrestricted)
2. New credentials:
    - **Kind:** Username with password
    - **Scope:** Global
    - **Username:** Your Docker Username
    - **Passowrd:** Your PAT from DockerHub
    - **ID:** `docker`
    - Create

### Login to your Docker Account in the Instance

```bash
docker login -u supersection
# User your PAT from DockerHub
```

### Install Docker Scout

```bash
sudo su
curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s -- -b /usr/local/bin
```

---

## Configure Jenkins Tools

### Add JDK

1. Dashboard > Manage Jenkins > Tools > "JDK installations"
2. Add JDK
    - **Name:** jdk
    - Install automatically:
        - Install from adoptium.net
        - **Version:** `jdk-17.0.1+12`

### Add NodeJS

1. Dashboard > Manage Jenkins > Tools > "NodeJS installations"
2. Add NodeJS
    - **Name:** node22
    - Install automatically:
        - Install from nodejs.org
        - **Version:** `NodeJS 22.16.0`

Apply and Save the new Tool installations

---

## Gmail SMTP Setup in Jenkins

### Create a App Password in Gmail

1. Open you Gmail > Manage your Google Account
2. In Security > Enable 2-Step Verification first
3. Seach "App Passwords"
4. Copy the code

### Set the App Password as Credential in Jenkins

1. Dashboard > Manage Jenkins > Credentials > System > Global credentials
2. New credentials:
    - **Kind:** Username with password
    - **Scope:** Global
    - **Username:** Your Email ID
    - **Passowrd:** App Password (that you just created)
    - **ID:** `smtp-token`
    - Create

### Configure E-mail Notification in Jenkins

1. Dashboard > Manage Jenkins > System
2. Scroll down at bottom, "E-mail Notification"
3. **SMTP Server:** smtp.gmail.com
4. **Default user e-mail suffix:** @gmail.com
5. Advanced:
    - Use SMTP Authentication
        - **User Name:** Your Email ID
        - **Password:** Paste your App Password
    - Use SSL
    - **SMTP Port:** 465
    - **Reply-To Address:** Provide your Email ID

6. You can Test configuration by sending test e-mail

#### Configure Extended E-mail Notification

1. Scroll a bit up to find "Extended E-mail Notification"
2. **SMTP Server:** smtp.gmail.com
3. **SMTP Port:** 587
4. Advanced:
    - **Credentials:** `smtp-token`
    - Use TSL
5. **Default user e-mail suffix:** @gmail.com

---

## Jenkins CI Pipeline

1. Add New Item and name it (`amazon-prime-video`)
2. Select **Pipeline** option > OK
3. Provide a description
4. Set "Discard old builds"
    - **Strategy**: Log Rotation
        - Days to keep builds: `1`
        - Max # of builds to keep: `3`

5. Pipeline script (Use Groovy Sandbox)
6. Click on *Pipeline Syntax*

### Configure Jenkins Pipeline `amazon-prime-video`

1. Dashboard > amazon-prime-video > Configure
2. Copy and Past the [Pipeline script](./Jenkinsfile)
3. Save and Apply the configuration
4. Build Now

---

## Setup IAM User and Access Key

1. Create an IAM user from [Amazon Console](https://aws.amazon.com/console/)
    - Provide User name: `amazon-prime-video`
    - Attach following policies:
        - AdministratorAccess
        - IAMFullAccess
        - AmazonVPCFullAccess
        - AmazonEC2FullAccess
        - AWSCloudFormationFullAccess
        - AmazonEKSClusterPolicy
        - AmazonEKSServicePolicy

2. Select the User and go to "Security credentials"
3. Create access key:
    - **User case:** Command Line Interface (CLI)
    - Tick the Confirmation

4. Copy the "Access key" and "Secret access key"

### Configure AWS CLI

``` bash
sudo su
aws configure
# Provide your credentials

# AWS Access Key ID [None]: YOUR_ACCESS_KEY
# AWS Secret Access Key [None]: your_secret_access_key
# Default region name [None]: us-east-1
# Default output format [None]: json
```

---

## Setup EKS Cluster with CLI

1. Create the EKS Cluster using `eksctl`

    ```bash
    eksctl create cluster --name=PrimeVideo \
    --region=us-east-1 \
    --zones=us-east-1a,us-east-1b \
    --version=1.31 \
    --without-nodegroup
    ```

2. Associating IAM OIDC Provider

    ```bash
    eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster PrimeVideo \
    --approve
    ```

### Setup Worker Nodes

Create the Node Group using `eksctl`:

```bash
eksctl create nodegroup --cluster PrimeVideo \
--region=us-east-1 \
--name=node2 \
--node-type=t3.medium \
--nodes=2 \
--nodes-min=2 \
--nodes-max=4 \
--node-volume-size=20 \
--ssh-access \
--ssh-public-key=SecOps-key \
--managed \
--asg-access \
--external-dns-access \
--full-ecr-access \
--appmesh-access \
--alb-ingress-access
```

---

## Setup AWS Credentials as Jenkins User

```bash
# Login as Jenkins user in the Instance
sudo -u jenkins -i
whoami

aws configure
aws sts get-caller-identity
```

---

## Jenkins CD Pipeline

1. Create a New Item
    - Provide a name (`eks-deployment`)
    - Select Pipeline
2. Copy & Paste the [EKS Deployment Pipeline script](./eks-deployment.Jenkinsfile)
3. Apply & Save
4. Build Now (CD pipeline)

---

## Setup Cloudflare DNS

Register a new Domain or yours existing domain to [Cloudflare](https://www.cloudflare.com/)

### Add CNAME Record

- Provide a subdomain
- Copy the Load balancer DNS and set it as Target
- Enable Proxy status in Cloudflare

---

## Setup Monitoring Sever using Terraform

### Set AWS Access Key as Credentials into Jenkins

1. Dashboard > Manage Jenkins > Credentials > System > Global credentials (unrestricted)
2. New Credentials:
    - **Kind:** Secret text
    - **Secret:** Access Key / Secret Access Key
    - **ID:** AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
    - **Description:** AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

### Setup Monitoring Server Pipeline

1. Create a New Item
    - Provide a name (`monitoring-server`)
    - Select Pipeline

2. Set "Discard old builds":
    - **Strategy**: Log Rotation
        - Days to keep builds: `1`
        - Max # of builds to keep: `2`

3. Set "This project is parameterized":
    - Select "Choice Parameter":
        - **Name:** `action`
        - **Choices:**

            ```txt
            apply
            destroy
            ```

4. Copy & Paste the [Monitoring Server Jenkins Pipeline script](./terraform/jenkinsfile)

---

## Configure Monitoring

1. Login to your `Monitoring_Server`

    ```bash
    sudo su
    git -v
    git clone https://github.com/soumosarkar297/devops-tools-installer-scripts.git
    cd devops-tools-installer-scripts
    chmod +x *.sh

    ```

2. Install Grafana & Prometheus

    ```bash
    sh grafana.sh
    sh prometheus.sh
    ```

    You hvae to open PORT `3000` fot Grafana & PORT `9090` for Prometheus  in the `Monitoring_Server`

3. Install `nestat` to the `Monitoring_Server`

    ```bash
    apt install net-tools
    netstat -tulnp
    ```

4. Install blackbox_exporter from Official page of [Prometheus](https://prometheus.io/download/)

    ```bash
    wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.26.0/blackbox_exporter-0.26.0.linux-amd64.tar.gz
    tar -xvf blackbox_exporter-0.26.0.linux-amd64.tar.gz

    cd blackbox_exporter-0.26.0.linux-amd64
    ll -a
    ./blackbox_exporter &

    netstat -tulnp
    ```

    Open `9115` PORT also in the Security group of `Monitoring_Server`

5. Install `Prometheus metrics` plugin in Jenkins
    - Go to Dashboard > Manage Jenkins > Plugins > Available plugins
    - Restart Jenkins when installation is complete and no jobs are running

6. Access Grafana & Prometheus in browser:
    - Grafana: `<Monitoring_Server-public-ip>:3000`
        - Default username & password is `admin`
        - Create a new password
    - Prometheus: `<Monitoring_Server-public-ip>:9090`
        - Go to Status > Targets

### Configure Prometheus into Grafana

1. Add Data source
    - Connections > Data sources > Add data source
    - Select "prometheus" and provide **Prometheus server URL**
    - Save & test

### Configure Blackbox Exported into Prometheus

1. Access Blackbox Exporter: `http://<Monitoring_Server-public-ip>:9115/`
2. Follow the below steps:

    ```bash
    sudo su
    cd /etc/prometheus/
    nano prometheus.yml
    # Copy and paste the 'blackbox' & 'jenkins' job from `prometheus.yml` to the existing file

    # After saving the changes, kill the prometheus service
    netstat -tulnp
    kill <PID>

    # Check again if prometheus has started with new PID
    netstat -tulnp
    # If NOT, then...
    ./prometheus &
    ```

3. Check the prometheus sever: `http://<Monitoring_Server-public-ip>:9090/targets?search=`
4. Check the Balckbox Exporter: `http://<Monitoring_Server-public-ip>:9115/`

### Configure Grafana Dashboard

1. Go to Dashboards > Create dashboard
2. Import dashboard (Discard changes)
3. Find and import dashboards for common applications at [grafana.com/dashboards](https://grafana.com/grafana/dashboards/)
4. Search specific dashboard, copy & paste the ID, then "Load" it
    - Add **Jenkins** & **Blackbox Exporter** Dashboard to Grafana
5. Select "prometheus" default

#### Test Jenkins Job

Now you can create sample "hello world" testing pipeline and run it, it will reflect as successful or failed job in the Dashboard of Grafana.

---

## Delete the Resources used

### `terraform destroy` Monitoring Server

Go to `monitoring-server` pipeline, and Build with 'destroy' Parameter. It will successfully trigger the `terraform destroy` to delete monitoring server resources.

### Delete EKS Cluster

Login to you `APP_SERVER`, and follow the below command:

```bash
eksctl delete nodegroup --cluster=PrimeVideo --name=node2 --region=us-east-1 --wait

eksctl delete cluster --name=PrimeVideo --region=us-east-1 --wait
```

### Manually terminate the `APP_SERVER`

At last, Don't forget to terminate the `APP_SERVER` manually after all resources have been deleted.

---

## Author

- [Soumo Sarkar](https://linkedin.com/in/soumo-sarkar)
- GitHub Account: [SuperSection](https://github.com/SuperSection), [soumosarkar297](https://github.com/soumosarkar297)

## References

- [amazon-prime-video-kubernetes GitHub Repo](https://github.com/Aseemakram19/amazon-prime-video-kubernetes)
- [devops-tools-installer-scrips](https://github.com/soumosarkar297/devops-tools-installer-scripts.git)
