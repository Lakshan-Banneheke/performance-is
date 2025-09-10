#!/bin/bash

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

subscription=$(az account show --query id --output tsv)
resource_group=$RESOURCE_GROUP
tag=$TAG # <tag='useCase=Test'>

# Get list of resources with specified tag
resource_list=$(az resource list --tag "${tag}" --subscription "${subscription}")

# Get number of resources to be deleted
num_resources=$(echo "$resource_list" | jq length)
echo "Found $num_resources resources"

# Delete resources
for((i=0; i<num_resources; i++)); do
    name=$(echo "$resource_list" | jq .[$i].name | tr -d '"')
    type=$(echo "$resource_list" | jq .[$i].type | tr -d '"')
    
    echo "Deleting following resource ..."
    echo "Resource Name : $name | Resource Type: $type"
    
    az resource delete -g "${resource_group}" -n "${name}" --resource-type "${type}"
    echo ""
done

echo "Deleting the VM OS-Disk..."
az disk delete --name myosdisk -g "$resource_group" --yes
