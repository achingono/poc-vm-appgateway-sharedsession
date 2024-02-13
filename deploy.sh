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

# create resource group
RESOURCE_GROUP='rg-${NAME}-${LOCATION}-${CODE}'
az group create --name $RESOURCE_GROUP --location $LOCATION

# create a storage account
STORAGE_ACCOUNT=$(echo "stg${NAME}${CODE}" | tr '-' '')

# zip the source code
zip -r ./pkg/source.zip ./src

# Copy the bacpac file to the storage account
az storage azcopy blob upload --container $NAME --account-name $STORAGE_ACCOUNT --source ./pkg/database.bacpac --destination database.bacpac

# Copy the source code to the storage account
az storage azcopy blob upload --container $NAME --account-name $STORAGE_ACCOUNT --source ./pkg/source.zip --destination source.zip

# provision infrastructure
az deployment sub create \
    --name $NAME \
    --location $LOCATION \
    --template-file ./iac/main.bicep \
    --parameters name=$NAME \
    --parameters location=$LOCATION \
    --parameters uniqueSuffix=$CODE \
    --parameters adminUsername=$USERNAME \
    --parameters adminPassword=$PASSWORD

duration=$SECONDS
echo "End time: $(date)"
echo "$(($duration / 3600)) hours, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."