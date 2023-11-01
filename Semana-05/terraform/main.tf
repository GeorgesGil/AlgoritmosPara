terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}


provider "digitalocean" {
  token = var.token
}


# Create a new Droplet
resource "digitalocean_droplet" "jenkins" {
  image    = "ubuntu-18-04-x64"
  name     = "jenkins"
  region   = "nyc3"
  size     = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_fingerprint]


  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.private_key)
    timeout     = "2m"
  }

  # User data to install Docker, Git, and Jenkins
user_data = <<-EOF
#!/bin/bash
sudo apt-get update -y
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt-get update
sudo apt-get install docker-ce -y
sudo systemctl start docker
sudo systemctl enable docker
sudo apt-get install git -y
sudo apt-get install openjdk-8-jdk -y
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
# Instalar Terraform
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sleep 30
git clone https://github.com/GeorgesGil/AlgoritmosParalelos.git
cd AlgoritmosParalelos/Semana-05/jenkins/jenkinsProject/jenkins
echo jenkinsfile

# Variables
JENKINS_URL="http://localhost:8080" # replace with your jenkins url
JOB_NAME="MyPipeline"
USERNAME="your-username"
PASSWORD="your-password"
CRUMB=$(curl -s "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" -u $USERNAME:$PASSWORD)
JENKINS_FILE=$(cat Jenkinsfile) # assuming the Jenkinsfile is in the same directory

# Create config.xml for the job
CONFIG_XML="<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin='workflow-job@2.40'>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class='org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition' plugin='workflow-cps@2.82'>
    <scm class='hudson.plugins.git.GitSCM' plugin='git@4.4.1'>
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/GeorgesGil/AlgoritmosParalelos.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class='list'/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>"

# Use Jenkins API to create job
curl -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
     -u $USERNAME:$PASSWORD \
     -H "$CRUMB" \
     -H "Content-Type:text/xml" \
     -d "$CONFIG_XML"
EOF
}

# Output the public IP address of the instance
output "public_ip" {
  value = digitalocean_droplet.jenkins.ipv4_address
}
