# -------------------------------------------------------------------------------------
#
# Copyright (c) 2021, WSO2 Inc. (http://www.wso2.com). All Rights Reserved.
#
# This software is the property of WSO2 Inc. and its suppliers, if any.
# Dissemination of any information or reproduction of any material contained
# herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
# You may not alter or remove any copyright or other notice from copies of this content.
#
# --------------------------------------------------------------------------------------

echo "Executing the Setup Script: VM Username : ${user}"
cd /home/${user}
export PATH=~/.local/bin:/usr/bin:$PATH
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -yq mysql-client
DEBIAN_FRONTEND=noninteractive apt-get install -y unzip
DEBIAN_FRONTEND=noninteractive env ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
export PATH=~/.local/bin:/usr/bin:/opt/mssql-tools/bin:$PATH
echo "export PATH=$PATH" >>/etc/environment
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo add-apt-repository universe
wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/powershell_7.1.3-1.ubuntu.18.04_amd64.deb
sudo dpkg -i powershell_7.1.3-1.ubuntu.18.04_amd64.deb
sudo apt-get install -y -f
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
sudo su
echo "export JAVA_HOME=/usr/lib/jvm/jdk" >>/etc/environment
exit
source /etc/environment
