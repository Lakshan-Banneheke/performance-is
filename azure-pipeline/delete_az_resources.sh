# !/bin/bash

subscription=$(az account show --query id --output tsv)
resource_group=$RESOURCE_GROUP
tag=$TAG # <tag='useCase=Test'>

# Get list of resources with specified tag
resource_list=`az resource list --tag ${tag} --subscription ${subscription}`

# Get number of resources to be deleted
num_resources=`echo $resource_list | jq length`
echo "Found $num_resources resources"

# Delete resources
for((i=0; i<$num_resources; i++)); do
    name=`echo $resource_list | jq .[$i].name | tr -d '"'`
    type=`echo $resource_list | jq .[$i].type | tr -d '"'`
    
    echo "Deleting following resource ..."
    echo "Resource Name : $name | Resource Type: $type"
    
    az resource delete -g ${resource_group} -n ${name} --resource-type ${type}
    echo ""
done

echo "Deleting the VM OS-Disk..."
az disk delete --name myosdisk -g $resource_group --yes
