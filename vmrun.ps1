param (
    [Parameter(Mandatory=$true)]
    [string]$hostName,
    [Parameter(Mandatory=$true)]
    [string]$username,
    [Parameter(Mandatory=$true)]
    [string]$password,
    [Parameter(Mandatory=$true)]
    [string]$scriptPath,
    [Parameter(ValueFromRemainingArguments=$true)]
    [String[]]$arguments
)


# Create credential object for connection to VM
# https://stackoverflow.com/a/49868824
$securePassword = ConvertTo-SecureString -string $password -AsPlainText -Force;
$credential = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $securePassword;

# Create new session options object
$sessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck;

# Create new session
$session = New-PSSession -ConnectionUri "https://${hostName}:5986" -Credential $credential -SessionOption $sessionOptions;

# Copy scripts to remote server
# Copy-Item -Path $sourcePath -Destination $targetPath -Force -Recurse -Container -ToSession $session -Verbose:$verbose;

# Invoke commands on remote machine
# https://stackoverflow.com/a/56128168
Invoke-Command -Session $session -FilePath $scriptPath -ArgumentList $arguments

# Disconnect session
$session | Disconnect-PSSession | Remove-PSSession;