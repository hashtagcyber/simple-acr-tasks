export RESOURCE_GROUP_NAME="SimpleACRTasks"
export RESOURCE_REGION="eastus"

#ACR and Storage names must be globally unique
export ACR_NAME="hashtagcyberregistry"
export STORAGE_NAME="hashtagcyberstorage"

export FOLDER_NAME="projectdata"
export IDENTITY_NAME="storagebot"
export TASK_NAME="hourlystoragerun"
export TASK_IMAGE="storagebot:0.1"
export TASK_SCHEDULE="0 * * * *"
#Note: This variable is just for the sample container.
#  Use the --set option with 'az acr task create' command to set environment variables
export FILE_BASENAME="acr-test"

# Create resource group to hold the project resources
az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_REGION

# Create the Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP_NAME \
  --name $ACR_NAME --sku Basic --admin-enabled true

# Create the Azure Blob Storage Account
az storage account create -n $STORAGE_NAME -g $RESOURCE_GROUP_NAME \
 -l $RESOURCE_REGION --sku Standard_LRS

# Create the storage container
az storage container create \
    --name $FOLDER_NAME \
    --account-name $STORAGE_NAME

# Create User Assigned Managed Identity
az identity create -n $IDENTITY_NAME -g $RESOURCE_GROUP_NAME

# Grant permissions to storage
principalId=$(az identity show -n $IDENTITY_NAME -g $RESOURCE_GROUP_NAME --query principalId -otsv)
storageId=$(az storage account show -n $STORAGE_NAME --query id -otsv)

#Wait 10 seconds for the identity to be available for assignment
sleep 10
az role assignment create --assignee $principalId \
  --scope $storageId --role "Storage Blob Data Contributor"

# Get the password needed to login to ACR
acrURL=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP_NAME --query loginServer -otsv)
acrUser=$(az acr credential show -n $ACR_NAME -g $RESOURCE_GROUP_NAME --query username -otsv)
acrPass=$(az acr credential show -n $ACR_NAME -g $RESOURCE_GROUP_NAME --query passwords[0].value -otsv)

# Get the blob storage url
storageURL=$(az storage account show -n $STORAGE_NAME --query primaryEndpoints.blob -otsv)

# Get the assign-identity
roleIdentity=$(az identity show -g $RESOURCE_GROUP_NAME --name $IDENTITY_NAME --query id -otsv)
echo -e "\n\nSetup Complete\n Next Steps:\n1. Connect docker using:\n\tdocker login $acrURL
2. When prompted for credentials:\n\tUser: $acrUser\n\tPass: $acrPass
3. Tag your image for upload:\n\t docker tag $TASK_IMAGE $acrURL/$TASK_IMAGE
4. Upload your image to ACR:\n\t docker push $acrURL/$TASK_IMAGE
5. Return to this terminal and create your scheduled container run using:\n
az acr task create --name $TASK_NAME --registry $ACR_NAME --cmd \"-e STORAGE_URL=$storageURL -e STORAGE_CONTAINER=$FOLDER_NAME -e FILE_BASENAME=$FILE_BASENAME $acrURL/$TASK_IMAGE\" \\
\t--schedule \"$TASK_SCHEDULE\" --context /dev/null \\
\t--assign-identity $roleIdentity
\n\n Note: To run this task manually, execute the following command:
\t az acr task run --name $TASK_NAME --registry $ACR_NAME\n\n"
