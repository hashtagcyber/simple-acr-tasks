# simple-acr-tasks

## Simple ACR Tasks
Most of my experience is in AWS, but recently I've had an increased need to learn Azure stuff... Lucky for me, the major cloud providers are all at near feature parity for the things I like to do. Unlucky for me, Azure doesn't have the same amount of blog posts and blueprints that say, "Enter these 5 commands to do that thing you want". This project aims to cover a pattern I tend to use a lot...

1. Write a hacky script to get data and stuff it in S3 (Azure Storage)
2. Throw it in a container
3. Have the container run on a schedule
4. Profit

## Preparing the Environment
One thing I really do like about Azure is the cloud shell... Do you have a browser? You can run the Azure equivalent of "aws s3 ls" and "aws e2 describe-instances" from there, without having to install anything on your workstation. It's pretty cool.

AzurePrep.sh is a bash script intended to be copy/pasted into the Azure Shell. It will:
1. Create a new Azure Container Registry (Azure equivalent of ECR) [docs](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli)

  ***Note***: The script uses the ***Registry Admin Account***; it would be better to grant a different identity access [Docs](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions)

2. Create a new Azure Blob Storage Account (Azure equivalent of S3) [docs](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-cli)
3. Create a new Storage Container (Folder in the storage account) [docs](https://docs.microsoft.com/en-us/azure/storage/blobs/blob-containers-cli)
4. Create a new User Assigned Managed Identity (Azure equivalent of Instance Profile/ IAM Role for container) [docs](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azcli)
5. Grant the Identity R/W access to the storage container in step 3 [docs](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/howto-assign-access-cli)
6. Print the data you need for future steps to the screen:
  - Docker commands for pushing an image to ACR
  - "az" command for creating the ACR Task using that image

## Getting environmental variables into the container
Again, Azure docs don't provide much clarity... but you can use the `--cmd` switch to add in any parameters to be included with the `docker exec` command that executes when your ACR Task is triggered.


If we don't need anything fancy (just run the container):
```
az acr task create --name $TASKNAME \
  --registry $REGISTRYNAME --cmd $CONTAINER_URL \
  --schedule "$CRON_SCHEDULE" --context /dev/null \
  --assign-identity $IDENTITY_ID
```

***BUT***, if we want to inject environment variables into the container:
```
az acr task create --name $TASKNAME \
  --registry $REGISTRYNAME --cmd "-e VAR1=foo -e VAR2=bar $CONTAINER_URL" \
  --schedule "$CRON_SCHEDULE" --context /dev/null \
  --assign-identity $IDENTITY_ID
```
## Final thoughts
One neat feature of ACR tasks is the ability to build containers from a git repository, without the need for docker on the local machine. This means that instead of:
```
docker build -t blah:1.0
docker tag blah:1.0 mycontainerregistry.azure.io/blah:1.0
docker push mycontainerregistry.azure.io/blah:1.0
```
We can instead use Azure to do the heavy lifting by providing a url to the Dockerfile that it can clone, build, and deploy. That's pretty neat, but I haven't had time to unlock it's full potential yet.
