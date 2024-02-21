param (
    [Parameter(Mandatory=$true)]
    [string] $siteName = "",
    [Parameter(Mandatory=$false)]
    [string] $applicationPool = "",
    [Parameter(Mandatory=$false)]
    [string] $downloadPath = "C:\Install\Features",
    [Parameter(Mandatory=$false)]
    [string] $logPath = "C:\Install\Logs"
)

if ($null -eq $applicationPool -or "" -eq $applicationPool) {
    $applicationPool = $siteName;
}
$siteFolder = "C:\inetpub\$siteName";
$sitePath = "IIS:\Sites\$siteName";
$applicationPoolPath = "IIS:\AppPools\$applicationPool";

mkdir $siteFolder
mkdir $downloadPath;
mkdir $logPath;
$ProgressPreference = 'SilentlyContinue'; 

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
Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName IIS-DefaultDocument, `
                                                              IIS-HttpErrors;
# Enable IIS Remote Management
Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName IIS-ManagementService;
# Enable remote management for IIS
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name EnableRemoteManagement -Value 1 -Force
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name EnableLogging -Value 1 -Force
Set-ItemProperty -Path HKLM:\\SOFTWARE\\Microsoft\\WebManagement\\Server -Name TracingEnabled -Value 1 -Force
# Set IIS Remote Management Service to start automatically
Set-Service -Name WMSVC -StartupType Automatic;
# Start IIS Remote Management Service
Start-Service -Name WMSVC;

# Install C++ 2017 distributions
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'));
Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile "$downloadPath\vc_redist.x64.exe" -UseBasicParsing;
Unblock-File "$downloadPath\vc_redist.x64.exe";
Start-Process -FilePath "$downloadPath\vc_redist.x64.exe" -Wait -ArgumentList "/install /quiet /norestart /log `"$logPath\vc_redist.x64.log`"" -PassThru | Wait-Process;

Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x86.exe' -OutFile "$downloadPath\vc_redist.x86.exe" -UseBasicParsing;
Unblock-File "$downloadPath\vc_redist.x86.exe";
Start-Process -FilePath "$downloadPath\vc_redist.x86.exe" -Wait -ArgumentList "/install /quiet /norestart /log `"$logPath\vc_redist.x86.log`"" -PassThru | Wait-Process;

# Install ODBC Driver
#Invoke-WebRequest 'https://download.microsoft.com/download/c/5/4/c54c2bf1-87d0-4f6f-b837-b78d34d4d28a/en-US/18.2.1.1/x64/msodbcsql.msi' -OutFile "$downloadPath\msodbcsql18.msi";
#Start-Process "$PSScriptRoot\msodbcsql18.msi" 'IACCEPTMSOLEDBSQLLICENSETERMS=YES /qn' -PassThru | Wait-Process;
Invoke-WebRequest 'https://download.microsoft.com/download/f/1/3/f13ce329-0835-44e7-b110-44decd29b0ad/en-US/19.3.1.0/x64/msoledbsql.msi' -OutFile "$downloadPath\msodbcsql19.msi" -UseBasicParsing;
Unblock-File "$downloadPath\msodbcsql19.msi";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\msodbcsql19.msi`" IACCEPTMSOLEDBSQLLICENSETERMS=YES /qn /L*V `"$logPath\msodbcsql19.log`"" -PassThru | Wait-Process;

# Install IIS Rewrite Module
Invoke-WebRequest 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi' -OutFile "$downloadPath\rewrite_amd64_en-US.msi" -UseBasicParsing;
Unblock-File "$downloadPath\rewrite_amd64_en-US.msi";
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\rewrite_amd64_en-US.msi`" /qn /L*V `"$logPath\rewrite_amd64_en-US.log`"" -PassThru | Wait-Process;

# Install Web Deploy
Invoke-WebRequest 'https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi' -OutFile "$downloadPath\WebDeploy_amd64_en-US.msi" -UseBasicParsing;
Unblock-File "$downloadPath\WebDeploy_amd64_en-US.msi";
# https://serverfault.com/a/233786
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\WebDeploy_amd64_en-US.msi`" ADDLOCAL=ALL /qn /L*V `"$logPath\WebDeploy_amd64_en-US.log`" LicenseAccepted=`"0`"" -PassThru | Wait-Process;

# Unlock IIS Configuration sections
& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/asp;
& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers;
& c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/modules;

# Enable Fusion Logs
# https://stackoverflow.com/a/33013110
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name ForceLog         -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogFailures      -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogResourceBinds -Value 1               -Type DWord;
Set-ItemProperty -Path HKLM:\\Software\\Microsoft\\Fusion -Name LogPath          -Value 'C:\inetpub\logs\' -Type String;
mkdir C:\inetpub\logs -Force;

# Configure IIS Application Pool
Import-Module WebAdministration;
if (-not (Test-Path $applicationPoolPath)) {
    # Create  Application Pool
    New-WebAppPool -Name $applicationPool;
    Set-ItemProperty $applicationPoolPath -Name managedPipelineMode -Value Integrated;
    Set-ItemProperty $applicationPoolPath -Name managedRuntimeVersion -Value v4.0;
    Set-ItemProperty $applicationPoolPath -Name enable32BitAppOnWin64 -Value $False;
    Set-ItemProperty $applicationPoolPath -Name autoStart -Value $true;
}
else {
    # Configure  Application Pool
    $pool = Get-Item $applicationPoolPath; 
    $pool.ManagedPipelineMode = 'Integrated'; 
    $pool.ManagedRuntimeVersion = 'v4.0'; 
    $pool.Enable32BitAppOnWin64 = $false; 
    $pool.AutoStart = $true; 
    $pool | Set-Item;
}

if (-not (Test-Path $sitePath)) {
    # Change the port for the default web site
    if ($siteName -ne 'Default Web Site') {
        Set-ItemProperty "IIS:\Sites\Default Web Site" -Name bindings -Value @{protocol = "http"; bindingInformation = "*:88:" };
    } 
    # Create IIS Web Site
    New-Website -Name $siteName -PhysicalPath $siteFolder -ApplicationPool $applicationPool;
}
else {
    # Configure Core Web Site
    Set-ItemProperty $sitePath -name PhysicalPath -value $siteFolder;
}

# Create web.config file if it does not exist
if (-not (Test-Path "$siteFolder\web.config")) {

# Define the XML content as a multi-line string
$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appSettings>
        <add key="SQLProvider" value="SQLOLEDB" />
        <add key="SQLConnectionStringName" value="AzureSql" />
    </appSettings>
    <connectionStrings>
        <add name="AzureSql" connectionString="Server=localhost,1433;Initial Catalog=Poc;Integrated Security=true;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" providerName="System.Data.SqlClient" />
    </connectionStrings>
    <system.web>
        <compilation debug="true" />
        <customErrors mode="Off" />
        <sessionState mode="InProc" cookieless="false" timeout="20" />
    </system.web>
    <system.webServer>
        <httpErrors errorMode="Detailed" />
        <asp appAllowClientDebug="True" appAllowDebugging="True" scriptErrorSentToBrowser="True" enableParentPaths="True">
            <comPlus appServiceFlags="EnableTracker" />
            <limits maxRequestEntityAllowed="2147483647" />
            <session allowSessionState="true" timeout="00:20:00" />
        </asp>
    </system.webServer>
</configuration>
"@

# Write the XML content to the web.config file
Set-Content -Path "$siteFolder\web.config" -Value $xmlContent -Force
}

# Create default.asp file if it does not exist
if (-not (Test-Path "$siteFolder\default.asp")) {

# Define the HTML content as a multi-line string
$aspContent = @"
<!doctype html>  <head> <meta charset=utf-8> <meta content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"name=viewport> <base 
    href=/ > <title>$siteName</title> <link href=https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css rel=stylesheet> </head> <body> <nav 
    aria-label="main navigation"class=navbar role=navigation> <div class=navbar-brand> <a href=/ class=navbar-item> <img height=28 
    src="https://github.com/achingono/poc-vm-appgateway-sharedsession/blob/main/src/images/secure-scale-logo.png?raw=true"> </a> </div> <div 
    class=navbar-menu> <div class=navbar-start> <a href=/ class=navbar-item> Home </a> </div> </div> </nav> <div class=container> <section 
    class="hero is-large"> <div class=hero-body> <p class=title> Shared Session Demo (ASP) </p> <p class=subtitle>
     How to share session between Classic ASP and ASP.Net </p> <p>Coming at you from <%= Environment.Item("COMPUTERNAME") %></p>
     </div> </section> </div>  <footer class=footer> <div class="content has-text-centered"> <p>
     <strong>Created</strong> by <a href=https://www.chingono.com>Alfero Chingono</a>. The source code is licensed <a 
    href=http://opensource.org/licenses/mit-license.php>MIT</a>. The website content is licensed <a 
    href=http://creativecommons.org/licenses/by-nc-sa/4.0/ >CC BY NC SA 4.0</a>. </p> </div> </footer> 
"@ 

# Write the ASP content to the default.asp file
Set-Content -Path "$siteFolder\default.asp" -Value $aspContent -Force
}

# Set file permissions
cmd /c icacls $siteFolder /grant:r Everyone:F /t;