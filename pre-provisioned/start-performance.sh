#!/bin/bash -e
# Copyright (c) 2021, wso2 Inc. (http://wso2.org) All Rights Reserved.
#
# wso2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------
# Run Identity Server Performance tests for two node cluster deployment.
# ----------------------------------------------------------------------------

source ../common/common-functions.sh

script_start_time=$(date +%s)
timestamp=$(date +%Y-%m-%d--%H-%M-%S)

random_number=$RANDOM
# random_number=21265

bastion_user="azureuser"
rds_host=""
jmeter_setup=""
cloud_host_name=""
mode=""
bastion_node_ip=""

results_dir="$PWD/results-$timestamp"

function usage() {
    echo ""
    echo "Usage: "
    echo "$0  -c <certificate_name> -j <jmeter_setup_path> -n <IS_zip_file_path>"
    echo "   [-u <db_username>] [-p <db_password>]"
    echo "   [-b <bastion_node_ip>]"
    echo "   [-h]"
    echo ""
    echo "-j: The path to JMeter setup."
    echo "-n: RDS Hostname. Default: $rds_host."
    echo "-d: Cloud Hostname: $cloud_host_name."
    echo "-t: The required testing mode [FULL/QUICK]"
    echo "-b: The IP address of the bastion node."
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "j:n:t:d:b:h" opts; do
    case $opts in
    j)
        jmeter_setup=${OPTARG}
        ;;
    d)
        cloud_host_name=${OPTARG}
        ;;
    n)
        rds_host=${OPTARG}
        ;;
    t)
        mode=${OPTARG}
        ;;
    b)
        bastion_node_ip=${OPTARG}
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

echo "Installed Python Version:" 
python --version
echo "Run mode: $mode"

run_performance_tests_options="$@"
echo $run_performance_tests_options

# if [[ ! -z $servicePrincipalId ]]; then
#     bastion_user=$servicePrincipalId
# fi
# export bastion_user

echo "Bastion IP address: $bastion_node_ip"

run_performance_tests_options+=(" -l $cloud_host_name -v $mode")
echo $run_performance_tests_options

# Checking for the availability of commands in jenkins.
check_command bc
check_command unzip
check_command jq
check_command python

mkdir "$results_dir"
echo ""
echo "Results will be downloaded to $results_dir"

echo ""
echo "Extracting IS Performance Distribution to $results_dir"
tar -xf target/is-performance-pre-provisioned*.tar.gz -C "$results_dir"

cp run-performance-tests.sh "$results_dir"/jmeter/
# estimate_command="$results_dir/jmeter/run-performance-tests.sh -t ${run_performance_tests_options[@]}"
# echo ""
# echo "Estimating time for performance tests"
# # Estimating this script will also validate the options. It's important to validate options before creating the stack.
# $estimate_command

temp_dir=$(mktemp -d)

echo ""
echo "Copying files to Bastion node..."
echo "============================================"

ssh -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com $bastion_user@$bastion_node_ip "sudo chown $bastion_user:$bastion_user /home/$bastion_user"
copy_setup_files_command="scp -i ~/.ssh/azure_id_rsa -v -r -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com $results_dir/setup $bastion_user@$bastion_node_ip:/home/$bastion_user/"
copy_repo_setup_command="scp -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com target/is-performance-pre-provisioned-*.tar.gz \
    $bastion_user@$bastion_node_ip:/home/$bastion_user/"

echo "$copy_setup_files_command"
$copy_setup_files_command
echo "$copy_repo_setup_command"
$copy_repo_setup_command

# copy_jmeter_setup_command="scp -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com $jmeter_setup $bastion_user@$bastion_node_ip:/home/$bastion_user/"

# echo "$copy_jmeter_setup_command"
# $copy_jmeter_setup_command

echo ""
echo "Running Bastion Node setup script..."
echo "============================================"
setup_bastion_node_command="ssh -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com -t  $bastion_user@$bastion_node_ip \
    sudo ./setup/setup-bastion.sh -r $rds_host -l $cloud_host_name -u $bastion_user"
echo "$setup_bastion_node_command"
# Handle any error and let the script continue.
$setup_bastion_node_command || echo "Remote ssh command failed."


echo ""
echo "Running performance tests..."
echo "============================================"
scp -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com run-performance-tests.sh $bastion_user@$bastion_node_ip:/home/$bastion_user/workspace/jmeter
echo "Run Type: $mode"

run_performance_tests_command="./workspace/jmeter/run-performance-tests.sh -p 443 ${run_performance_tests_options[@]}"

run_remote_tests="ssh -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com -t  $bastion_user@$bastion_node_ip $run_performance_tests_command"
echo "$run_remote_tests"
$run_remote_tests || echo "Remote test ssh command failed."

echo ""
echo "Downloading results..."
echo "============================================"
echo "============================================"
download="scp -i ~/.ssh/azure_id_rsa -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ecdsa-sha2-nistp256,ssh-rsa,ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-rsa-cert-v01@openssh.com $bastion_user@$bastion_node_ip:/home/$bastion_user/results.zip $results_dir/"
echo "$download"
$download || echo "Remote download failed"

if [[ ! -f $results_dir/results.zip ]]; then
    echo ""
    echo "Failed to download the results.zip"
    exit 0
fi

echo "Installing required Python packages..."
# sudo apt install -y python-pip
pip install numpy
echo "============================================"

echo ""
echo "Creating summary.csv..."
echo "============================================"
cd "$results_dir"

unzip -q results.zip
wget https://sourceforge.net/projects/gcviewer/files/gcviewer-1.35.jar/download -O gcviewer.jar
"$results_dir"/jmeter/create-summary-csv.sh -d results -n "WSO2 Thunder" -p thunder -c "Heap Size" \
    -c "Concurrent Users" -r "([0-9]+[a-zA-Z])_heap" -r "([0-9]+)_users" -i -l -k 2 -g gcviewer.jar
echo "Creating summary file..."
./summary/summary-modifier-pre-provisioned.py


rm -rf cf-test-metadata.json cloudformation/ common/ gcviewer.jar is/ jmeter/ jtl-splitter/ netty-service/ payloads/ results/ sar/ setup/ workspace/

echo ""
echo "Done."
