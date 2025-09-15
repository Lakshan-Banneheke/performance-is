#!/bin/bash

HOME="/home/azureuser"
PERFORMANCE_REPO="https://github.com/Lakshan-Banneheke/performance-is.git"
PERFORMANCE_REPO_BRANCH="thunder-new"
THUNDER_HOST_NAME="thunder.local"
DATABASE_HOST_NAME="wso2-thunder.postgres.database.azure.com"
BASTION_USER="azureuser"

echo "Downloading JMeter"
wget -P "$HOME" https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.3.tgz

# Update below script
user="azureuser"
echo "Executing the Setup Script: VM Username : ${user}"
cd /home/${user}

sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common


wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo add-apt-repository universe
wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/powershell_7.1.3-1.ubuntu.18.04_amd64.deb
sudo dpkg -i powershell_7.1.3-1.ubuntu.18.04_amd64.deb
sudo apt-get install -y -f

sudo apt remove --purge openjdk-21-jre-headless
curl -o jdk-setup.tar.gz https://s3.amazonaws.com/is-performance-test/java-setup/jdk-8u212-linux-x64.tar.gz
sudo mkdir /usr/lib/jvm
sudo tar -xvf jdk-setup.tar.gz -C /usr/lib/jvm
sudo mv /usr/lib/jvm/jdk* /usr/lib/jvm/jdk
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk/bin/java" 1
sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk/bin/javac" 1
sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk/bin/javaws" 1
sudo chmod a+x /usr/bin/java
sudo chmod a+x /usr/bin/javac
sudo chmod a+x /usr/bin/javaws
export JAVA_HOME=/usr/lib/jvm/jdk
sudo sh -c 'echo "export JAVA_HOME=/usr/lib/jvm/jdk" >> /etc/environment'
source /etc/environment

# echo "Cloning performance repository"
# git clone "$PERFORMANCE_REPO" "$HOME"/resources/performance-is
# cd "$HOME"/resources/performance-is
# git checkout "$PERFORMANCE_REPO_BRANCH"

# echo "Installing the project using mvn"
# sudo apt update
# sudo apt install maven -y
# cd pre-provisioned
# mvn clean install

# timestamp=$(date +%Y-%m-%d--%H-%M-%S)
# results_dir="$HOME/results-$timestamp"
# mkdir "$results_dir"
# echo "Extracting IS Performance Distribution to $results_dir"
# tar -xf target/is-performance-pre-provisioned*.tar.gz -C "$results_dir"
# sudo bash "$HOME"/resources/performance-is/pre-provisioned/setup/setup-bastion.sh -r "$DATABASE_HOST_NAME" -l "$THUNDER_HOST_NAME" -u "$BASTION_USER"