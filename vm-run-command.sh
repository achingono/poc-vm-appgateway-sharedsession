while getopts n:l:c:u:p:f: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LOCATION=${OPTARG};;
        c) CODE=${OPTARG};;
        u) USERNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        f) PACKAGE=${OPTARG};;
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

RESOURCE_GROUP="rg-${NAME}-${CODE}-${LOCATION}"
SITE_NAME="api-${NAME}-${CODE}"
VIRUTAL_MACHINE="vm-$SITE_NAME"
STORAGE_ACCOUNT=$(echo "stg${NAME}${CODE}" | tr -d -c 'a-z0-9')
STORAGE_CONTAINER="${NAME}-${CODE}"
SQL_SERVER="sql-${NAME}-${CODE}"
SQL_DATABASE="db-${NAME}-${CODE}"
REDIS_SERVER="redis-${NAME}-${CODE}"
DECRYPTION_KEY=$(openssl rand -hex 32)
VALIDATION_KEY=$(openssl rand -hex 64)

# Get SQL Connection string
SQL_CONNECTION_STRING=$(az sql db show-connection-string --client ado.net --name $SQL_DATABASE --server $SQL_SERVER --auth-type SqlPassword)

# Replace username and password in the connection string
SQL_CONNECTION_STRING=$(echo $SQL_CONNECTION_STRING | sed -e "s/<username>/$USERNAME/g" -e "s/<password>/$PASSWORD/g")

# Get Redis Parameters
REDIS_PARAMS=$(az redis show --name $REDIS_SERVER --resource-group $RESOURCE_GROUP --query [hostName,port,enableNonSslPort,sslPort] -o tsv)
REDIS_HOSTNAME=$(echo $REDIS_PARAMS | awk '{print $1}')
REDIS_PORT=$(echo $REDIS_PARAMS | awk '{print $4}')

# Get the Azure Redis Access Key
REDIS_ACCESS_KEY=$(az redis list-keys --name $REDIS_SERVER --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)

# Run command on the virtual machine
az vm run-command invoke --command-id RunPowerShellScript \
        --name $VIRUTAL_MACHINE --resource-group $RESOURCE_GROUP \
        --scripts @./deploy.ps1 \
        --parameters "siteName=$SITE_NAME" "packageName=$PACKAGE" \
                    "storageAccount=$STORAGE_ACCOUNT" "storageContainer=$STORAGE_CONTAINER" \
                    "sqlConnectionString=$SQL_CONNECTION_STRING" "redisHost=$REDIS_HOSTNAME" \
                    "redisKey=$REDIS_ACCESS_KEY" "redisPort=$REDIS_PORT" \
                    "decryptionKey=$DECRYPTION_KEY" "validationKey=$VALIDATION_KEY"
