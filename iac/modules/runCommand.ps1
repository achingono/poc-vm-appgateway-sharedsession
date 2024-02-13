param (
    [Parameter(Mandatory=$true)]
    [string] $storageAccountName,
    [Parameter(Mandatory=$true)]
    [string] $storageContainerName,
    [Parameter(Mandatory=$true)]
    [string] $storageFileName,
    [Parameter(Mandatory=$true)]
    [string] $storageKey,
    [Parameter(Mandatory=$false)]
    [string] $downloadPath = "C:\Install\Features",
    [Parameter(Mandatory=$false)]
    [string] $logPath = "C:\Install\Logs",
    [Parameter(Mandatory=$false)]
    [string] $siteName = "Default Web Site",
    [Parameter(Mandatory=$false)]
    [string] $applicationPool = "DefaultAppPool",
    [Parameter(Mandatory=$false)]
    [string] $sitePath = "IIS:\Sites\$siteName",
    [Parameter(Mandatory=$false)]
    [string] $applicationPoolPath = "IIS:\\AppPools\\$applicationPool"
)
$codePath = "C:\Source";
$nugetPath = "$codePath\nuget";
$packagesPath = "$codePath\packages";
$binPath = "$codePath\bin";

# Configure WinRM for HTTPS
Enable-PSRemoting -Force;
New-NetFirewallRule -Name "Allow WinRM HTTPS" -DisplayName "Windows Remote Management (HTTPS-In)" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP;
$thumbprint = (New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My).Thumbprint;
$command = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=""$env:computername""; CertificateThumbprint=""$thumbprint""}";
cmd.exe /C $command;

# Add Windows Features
Add-WindowsFeature Web-Server, `
                   NET-Framework-45-ASPNET, `
                   Web-Asp-Net45; 
&$Env:windir\Microsoft.NET\Framework64\v4.0.30319\ngen update; 
&$Env:windir\Microsoft.NET\Framework\v4.0.30319\ngen update;

# Install Windows Features
Install-WindowsFeature Web-ASP, `
                       Web-CGI, `
                       Web-ISAPI-Ext, `
                       Web-ISAPI-Filter, `
                       Web-Includes, `
                       Web-HTTP-Errors, `
                       Web-Common-HTTP, `
                       Web-Performance, `
                       WAS, `
                       Web-Mgmt-Console, `
                       Web-Mgmt-Service, `
                       Web-Scripting-Tools;

# Enable IIS Features
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument, `
                                                   IIS-HttpErrors;
# Enable IIS Remote Management
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementService;
# Enable remote management for IIS
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name EnableRemoteManagement -Value 1 -Force
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name EnableLogging -Value 1 -Force
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name TracingEnabled -Value 1 -Force
# Set IIS Remote Management Service to start automatically
Set-Service -Name WMSVC -StartupType Automatic;
# Start IIS Remote Management Service
Start-Service -Name WMSVC;

mkdir $downloadPath;
mkdir $logPath;
$ProgressPreference = 'SilentlyContinue'; 

# Install C++ 2017 distributions
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'));
Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile "$downloadPath\vc_redist.x64.exe" -UseBasicParsing;
Unblock-File "$downloadPath\vc_redist.x64.exe";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\vc_redist.x64.exe`" /qn ALLUSERS=1 REBOOT=ReallySuppress /L*V `"$logPath\vc_redist.x64.log`"" -PassThru | Wait-Process;

Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x86.exe' -OutFile "$downloadPath\vc_redist.x86.exe" -UseBasicParsing;
Unblock-File "$downloadPath\vc_redist.x86.exe";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\vc_redist.x86.exe`" /qn ALLUSERS=1 REBOOT=ReallySuppress /L*V `"$logPath\vc_redist.x86.log`"" -PassThru | Wait-Process;

# Install ODBC Driver
#Invoke-WebRequest 'https://download.microsoft.com/download/c/5/4/c54c2bf1-87d0-4f6f-b837-b78d34d4d28a/en-US/18.2.1.1/x64/msodbcsql.msi' -OutFile "$downloadPath\msodbcsql18.msi";
#Start-Process "$PSScriptRoot\msodbcsql18.msi" 'IACCEPTMSODBCSQLLICENSETERMS=YES /qn' -PassThru | Wait-Process;
Invoke-WebRequest 'https://download.microsoft.com/download/f/1/3/f13ce329-0835-44e7-b110-44decd29b0ad/en-US/19.3.1.0/x64/msoledbsql.msi' -OutFile "$downloadPath\msodbcsql19.msi" -UseBasicParsing;
Unblock-File "$downloadPath\msodbcsql19.msi";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\msodbcsql19.msi`" IACCEPTMSOLEDBCSQLLICENSETERMS=YES /qn /L*V `"$logPath\msodbcsql19.log`"" -PassThru | Wait-Process;

# Install IIS Rewrite Module
Invoke-WebRequest 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi' -OutFile "$downloadPath\rewrite_amd64_en-US.msi" -UseBasicParsing;
Unblock-File "$downloadPath\rewrite_amd64_en-US.msi";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\rewrite_amd64_en-US.msi`" /qn /L*V `"$logPath\rewrite_amd64_en-US.log`"" -PassThru | Wait-Process;

# Install Web Deploy
Invoke-WebRequest 'https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi' -OutFile "$downloadPath\WebDeploy_amd64_en-US.msi" -UseBasicParsing;
Unblock-File "$downloadPath\WebDeploy_amd64_en-US.msi";
# https://serverfault.com/a/233786
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\WebDeploy_amd64_en-US.msi`" ADDLOCAL=ALL /qn /L*V `"$logPath\WebDeploy_amd64_en-US.log`" LicenseAccepted=`"0`"" -PassThru | Wait-Process;

Import-Module WebAdministration;
$pool = Get-Item $applicationPoolPath;
$pool.ManagedPipelineMode       = 'Integrated';
$pool.ManagedRuntimeVersion     = 'v4.0';
$pool.Enable32BitAppOnWin64     = $false;
$pool.AutoStart                 = $true;
$pool | Set-Item;

& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/asp;
& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers;
& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/modules;

Set-WebConfigurationProperty -Location $siteName -Filter "system.webServer/asp" -Name "enableParentPaths" -Value 'True';
Set-WebConfigurationProperty -Location $siteName -Filter "system.webServer/asp/limits" -Name "maxRequestEntityAllowed" -Value 2000000000;

# Enable Fusion Logs
# https://stackoverflow.com/a/33013110
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name ForceLog         -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogFailures      -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogResourceBinds -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogPath          -Value 'C:\inetpub\logs\' -Type String;
mkdir C:\inetpub\logs -Force;

# Install Azure CLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "$downloadPath\AzureCLI.msi"; 
Start-Process msiexec.exe -Wait -ArgumentList "/I `"$downloadPath\AzureCLI.msi`" /quiet"; 
az config set extension.use_dynamic_install=yes_without_prompt;

# Download Source Code
az config set extension.use_dynamic_install=yes_without_prompt;
az storage azcopy blob download --account-name $storageAccountName --container $storageContainerName --source $storageFileName --destination "$downloadPath\$storageFileName" --account-key $storageKey;

# Unzip Source Code
Expand-Archive -Path "$downloadPath\$storageFileName" -DestinationPath $codePath -Force;

# download the nuget binary
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = "$nugetPath\nuget.exe"
mkdir -Path $nugetPath
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
Set-Alias nuget $targetNugetExe -Scope Global -Verbose
# install nuget package
nuget install Microsoft.Web.RedisSessionStateProvider -OutputDirectory $nugetPackagesPath -Framework net46
# copy binaries to bin folder
Get-ChildItem -Path $nugetPackagesPath -Recurse | Where-Object { $_.FullName -match "\\lib\\net4.*\\.*\.dll"} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $binPath
}