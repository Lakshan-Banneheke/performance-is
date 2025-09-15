#!/bin/bash +x
# Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com).
#
# WSO2 LLC. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------
# Run Identity Server Performance tests for two node cluster deployment.
# ----------------------------------------------------------------------------

BUILD_JOB_NAME="thunder-performance-is-pre-provisioned-wso2.com"

# Create workspace. 
BUILD_DIR=$(pwd)
RESOURCES_DIR=$BUILD_DIR/resources
WORKSPACE=$BUILD_DIR/performance-is
cd $BUILD_DIR
mkdir resources
dig +short myip.opendns.com @resolver1.opendns.com
echo "Build Dir:$BUILD_DIR | Resources_Dir: $RESOURCES_DIR | Workspace: $WORKSPACE"
cmd=""
MODE=$RUN_MODE

git config --global user.email "$GITHUB_USER_EMAIL"
git config --global user.name "$GITHUB_USERNAME"

echo "$BUILD_TYPE"

echo ""
echo "Starting performance test with params:"
echo "    CONCURRENT_USERS: $CONCURRENT_USERS"
echo "    MODE: $MODE"
echo "    PURPOSE: $BUILD_PURPOSE"
echo "=========================================================="
echo "Thunder Perf Environment - Status: "
curl -s -i https://thunder.local/health/liveness | head -1

echo "Changing Directory to Thunder Product Repository | Branch: $BRANCH"
cd $WORKSPACE

rm -rf ~/.ssh/
mkdir ~/.ssh
chmod 700 ~/.ssh

wget -P "$RESOURCES_DIR" https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.3.tgz

echo "Add Azure SSH extension"
az extension add --name ssh

cd pre-provisioned

# Build and run perf-tests.
echo ""
echo "Building project..."
echo "=========================================================="
mvn clean install

echo ""
echo "Starting test..."
echo "=========================================================="
  
# Define and execute start-performance command.
echo "Bastion IP init: $BASTION_NODE_IP"
cmd="./start-performance.sh -j $RESOURCES_DIR/apache-jmeter-3.3.tgz -b $BASTION_NODE_IP -n $DATABASE_HOST_NAME -d $THUNDER_HOST_NAME -t $MODE -- -d 15 -w 2 -q $POPULATE_TEST_DATA -c $CONCURRENT_USERS"

$cmd

# Copy results directory to build path to be saved as a build artifact.
cp -r results-* $BUILD_PATH/

rm -rf ~/.ssh/

#copy summary csv to new directory and push to github.
timestamp=$(date +%Y-%m-%d--%H-%M-%S)
summary_filename="summary-$timestamp"
detailed_summary_filename="summary_detailed-$timestamp"

BM_DIR="../benchmarks/"
if [ ! -d "$BM_DIR" ]; then
    mkdir $BM_DIR
fi

mkdir ../benchmarks/$BUILD_NUM
cp results-*/summary.csv ../benchmarks/$BUILD_NUM/
cut -d',' -f -9 results-*/summary-original.csv > ../benchmarks/$BUILD_NUM/$detailed_summary_filename.csv
cd ..
mv benchmarks/$BUILD_NUM/summary.csv benchmarks/$BUILD_NUM/$summary_filename.csv

#Create a readme file for benchmarks
cat <<EOF >> benchmarks/$BUILD_NUM/readme.md
Build Number: $BUILD_NUM

Build Date and Time: $timestamp

Build Purpose: $BUILD_PURPOSE
------------------------------------------------

Concurrent Users: $CONCURRENT_USERS

Number of SP's per Tenant: $SP_PER_TENANT

Number of Users per Tenant: $USERS_PER_TENANT

Performance-Artifacts repo branch name: $BRANCH
EOF

git add benchmarks/$BUILD_NUM/
git commit -m "Add performance benchmarks from test at $timestamp"
git pull origin $BRANCH
git push -u origin $BRANCH
