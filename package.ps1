
$siteCodeFolder = $PSScriptRoot
$sitePackageFolder = "$((Get-Item $siteCodeFolder).Parent.FullName)\pkg";
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe";
$targetNugetExe = "$nugetPath\nuget.exe";

# download the nuget binary
mkdir -Path $nugetPath
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
Set-Alias nuget $targetNugetExe -Scope Global -Verbose
# install nuget package
nuget install Microsoft.Web.RedisSessionStateProvider -OutputDirectory $nugetPackagesPath -Framework net46
# copy binaries to bin folder
Get-ChildItem -Path $nugetPackagesPath -Recurse | Where-Object { $_.FullName -match "\\lib\\net4.*\\.*\.dll"} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $binPath
}

# install nuget packages
nuget install Microsoft.Web.Xdt -OutputDirectory $nugetPackagesPath
nuget install SlowCheetah.Xdt -OutputDirectory $nugetPackagesPath

# locate the SlowCheeter executable
$transformerPath = (Get-ChildItem -Path $nugetPackagesPath -Include 'SlowCheetah.Xdt.exe' -Recurse) | Select-Object -First 1

# locate the Xdt dll
$xdtPath = (Join-Path $transformerPath.Directory.FullName 'Microsoft.Web.XmlTransform.dll')
if(!(Test-Path $xdtPath)){
    # copy the xdt.dll next to the slowcheetah .exe
    $xdtDll = (Get-ChildItem -Path $nugetPackagesPath -Include 'Microsoft.Web.XmlTransform.dll' -Recurse) | Select-Object -First 1

    if(!$xdtDll){ throw 'Microsoft.Web.XmlTransform.dll not found' }

    Copy-Item -Path $xdtDll.Fullname -Destination $xdtPath | Out-Null
}

# Transform web.config
# https://gist.github.com/sayedihashimi/f1fdc4bfba74d398ec5b
# slowcheetah.xdt.exe <source file> <transform> <dest file>
$cmdArgs = @("$siteCodeFolder\web.config",
             "$siteCodeFolder\web.release.config",
             "$siteCodeFolder\web.config");

'Calling slowcheetah.xdt.exe with the args: [{0} {1}]' -f (GetTransformXmlExe), ($cmdArgs -join ' ') | Write-Verbose
&($transformerPath -toolsDir $toolsDir) $cmdArgs;

# create deployment package 
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd569054(v=ws.10)
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd569019(v=ws.10)
& 'C:\Program Files (x86)\IIS\Microsoft Web Deploy V3\msdeploy.exe' -verb:sync `
        -source:iisApp="$siteCodeFolder",includeAcls=false,enable32BitAppOnWin64=false,managedPipelineMode=Integrated,managedRuntimeVersion='v4.0' `
        -dest:package="$sitePackageFolder\package.zip" `
        -declareParamFile="$siteCodeFolder\parameters.xml"