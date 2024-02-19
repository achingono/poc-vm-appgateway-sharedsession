param (
    [Parameter(Mandatory = $true)]
    [string] $siteName,
    [Parameter(Mandatory = $true)]
    [string] $packageName,
    [Parameter(Mandatory = $true)]
    [string] $storageAccount,
    [Parameter(Mandatory = $true)]
    [string] $storageContainer,
    [Parameter(Mandatory = $true)]
    [string] $sqlConnectionString,
    [Parameter(Mandatory = $true)]
    [string] $redisHost,
    [Parameter(Mandatory = $true)]
    [string] $redisKey,
    [Parameter(Mandatory = $false)]
    [string] $redisPort = "6380",
    [Parameter(Mandatory = $false)]
    [ValidateSet("true", "false")]
    [string] $redisSsl = "true",
    [Parameter(Mandatory = $false)]
    [string] $downloadPath = "C:\Install\Packages"
)

# Generate package URI
$packageUri = "https://$storageAccount.blob.core.windows.net/$storageContainer/$packageName";
$packagePath = "$downloadPath\$packageName";

# Download the Source Code
mkdir $downloadPath -ErrorAction SilentlyContinue;
Invoke-WebRequest -Uri $packageUri -OutFile $packagePath; 

# Generate the parameters XML file from the hashtable
$parametersXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<parameters>
  <setParameter name="SQL Connection String" value="$sqlConnectionString" />
    <setParameter name="Redis Host" value="$redisHost" />
    <setParameter name="Redis Key" value="$redisKey" />
    <setParameter name="Redis Port" value="$redisPort" />
    <setParameter name="Redis SSL" value="$redisSsl" />
</parameters>
"@;

# Save the parameters XML file
$parametersFile = $packageName -replace ".zip", ".xml";
$parametersXml | Out-File -FilePath "$downloadPath\$parametersFile";

# Deploy the package to the Site
& "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe" '-verb=sync' '-source=package=$packagePath' `
    "-dest=iisApp=$siteName" "-setParamFile=$downloadPath\$parametersFile" '-verbose' '-debug';
