while getopts n:l:c:u:p: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LOCATION=${OPTARG};;
        c) CODE=${OPTARG};;
        u) USERNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
    esac
done

if [ "$NAME" == "" ] || [ "$LOCATION" == "" ] || [ "$CODE" == "" ] || [ "$USERNAME" == "" ] || [ "$PASSWORD" == "" ]; then
 echo "Syntax: $0 -n <name> -l <location> -c <unique code> -u <admin username> -p <admin password>"
 exit 1;
elif [[ $CODE =~ [^a-zA-Z0-9] ]]; then
 echo "Unique code must contain ONLY letters and numbers. No special characters."
 echo "Syntax: $0 -n <name> -l <location> -c <unique code> -u <admin username> -p <admin password>"
 exit 1;
fi

SECONDS=0
echo "Start time: $(date)"

# configure az cli dynamic install
az config set extension.use_dynamic_install=yes_without_prompt;

# create resource group
RESOURCE_GROUP="rg-${NAME}-${LOCATION}-${CODE}"
az group create --name $RESOURCE_GROUP --location $LOCATION

STORAGE_ACCOUNT="stg${NAME}${CODE}"
STORAGE_CONTAINER="${NAME}-${CODE}"
# remove invalid characters from the storage account name
STORAGE_ACCOUNT=$(echo $STORAGE_ACCOUNT | tr -d -c 'a-z0-9')
# create a storage account
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --allow-blob-public-access true

# wait for the storage account to be created
while [[ $(az storage account show --name $STORAGE_ACCOUNT \
                --resource-group $RESOURCE_GROUP \
                --query "provisioningState" \
                --output tsv) != "Succeeded" ]]; do
sleep 5
done

# create a container
az storage container create --name $STORAGE_CONTAINER --account-name $STORAGE_ACCOUNT --public-access blob

# check if the bacpac file exists in storage container
BACPAC_EXISTS=$(az storage blob exists --container-name $STORAGE_CONTAINER \
                --name database.bacpac \
                --account-name $STORAGE_ACCOUNT)

if [[ $BACPAC_EXISTS == *"false"* ]]; then                

    # Copy the bacpac file to the storage account
    az storage azcopy blob upload --container $STORAGE_CONTAINER --account-name $STORAGE_ACCOUNT --source ./pkg/database.bacpac --destination database.bacpac

fi

# check if the bacpac file exists in storage container
ZIP_EXISTS=$(az storage blob exists --container-name $STORAGE_CONTAINER \
                --name database.bacpac \
                --account-name $STORAGE_ACCOUNT)

if [[ $ZIP_EXISTS == *"false"* ]]; then                

    # zip the source code
    zip -r ./pkg/source.zip ./src -x "./src/bin/*" "./src/packages/*"

    # Copy the source code to the storage account
    az storage azcopy blob upload --container $STORAGE_CONTAINER --account-name $STORAGE_ACCOUNT --source ./pkg/source.zip --destination source.zip

fi
# provision infrastructure
az deployment sub create \
    --name $NAME \
    --location $LOCATION \
    --template-file ./iac/main.bicep \
    --parameters name=$NAME \
    --parameters location=$LOCATION \
    --parameters uniqueSuffix=$CODE \
    --parameters adminUsername=$USERNAME \
    --parameters adminPassword=$PASSWORD \
    --parameters sourcePackageName=source.zip #\
#    --parameters databasePackageName=database.bacpac

# import the bacpac file
az sql db import --name "db-${NAME}-${CODE}" \
    --server "sql-${NAME}-${CODE}" --resource-group $RESOURCE_GROUP \
     --auth-type SQL --admin-user $USERNAME --admin-password $PASSWORD \
    --storage-uri https://$STORAGE_ACCOUNT.blob.core.windows.net/$STORAGE_CONTAINER/database.bacpac \
    --storage-key $(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "[0].value" -o tsv) \
    --storage-key-type StorageAccessKey

# remove sql server firewall rule
az sql server firewall-rule delete --name "AllowAllWindowsAzureIps" --resource-group $RESOURCE_GROUP --server "sql-${NAME}-${CODE}"

# remove the source code
rm ./pkg/source.zip

duration=$SECONDS
echo "End time: $(date)"
echo "$(($duration / 3600)) hours, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."