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
    [Parameter(Mandatory = $true)]
    [string] $decryptionKey,
    [Parameter(Mandatory = $true)]
    [string] $validationKey,
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

# Create an instance of the XmlDocument class
$xmlDoc = New-Object System.Xml.XmlDocument;

# Create the XML declaration
$xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null);
$xmlDoc.AppendChild($xmlDeclaration);

# Create the root element
$parametersElement = $xmlDoc.CreateElement("parameters");
$xmlDoc.AppendChild($parametersElement);

# Helper function to create and append a parameter element
Function AddParameterElement($name, $value) {
    $parameterElement = $xmlDoc.CreateElement("setParameter");
    $nameAttribute = $xmlDoc.CreateAttribute("name");
    $valueAttribute = $xmlDoc.CreateAttribute("value");

    $nameAttribute.Value = $name;
    $valueAttribute.Value = [System.Security.SecurityElement]::Escape($value);

    $parameterElement.Attributes.Append($nameAttribute);
    $parameterElement.Attributes.Append($valueAttribute);

    $parametersElement.AppendChild($parameterElement);
}

# Add parameters
AddParameterElement "SQL Connection String" $sqlConnectionString;
AddParameterElement "Redis Host" $redisHost;
AddParameterElement "Redis Key" $redisKey;
AddParameterElement "Redis Port" $redisPort;
AddParameterElement "Redis SSL" $redisSsl;
AddParameterElement "Decryption Key" $decryptionKey;
AddParameterElement "Validation Key" $validationKey;

# Save the parameters XML file
$parametersFile = $packageName -replace ".zip", ".xml";
$xmlDoc.Save("$downloadPath\$parametersFile");

# Deploy the package to the Site
& 'C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe' '-verb=sync' "-source=package=$packagePath" `
    "-dest=iisApp=$siteName" "-setParamFile=$downloadPath\$parametersFile" '-verbose' '-debug';
