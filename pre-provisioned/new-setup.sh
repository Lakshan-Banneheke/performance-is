#!/bin/bash

HOME="/home/azureuser"
PERFORMANCE_REPO="https://github.com/Lakshan-Banneheke/performance-is.git"
PERFORMANCE_REPO_BRANCH="thunder-new"
THUNDER_HOST_NAME="thunder.local"
DATABASE_HOST_NAME="wso2-thunder.postgres.database.azure.com"
BASTION_USER="azureuser"

mkdir "$HOME"/resources

echo "Downloading JMeter"
wget -P "$HOME"/resources https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.3.tgz

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