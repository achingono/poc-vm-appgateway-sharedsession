
$siteCodeFolder = "$PSScriptRoot\src";
$sitePackageFolder = "$((Get-Item $siteCodeFolder).Parent.FullName)\pkg";
$nugetPath = "$((Get-Item $siteCodeFolder).Parent.FullName)\.nuget";
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe";
$targetNugetExe = "$nugetPath\nuget.exe";
$nugetPackagesPath = "$nugetPath\packages";
$binPath = "$siteCodeFolder\bin";
$sourceConfig = "$siteCodeFolder\web.config";
$transformConfig = "$siteCodeFolder\web.release.config";
$targetConfig = "$siteCodeFolder\web.config";
$msdeploy = "C:\Program Files (x86)\IIS\Microsoft Web Deploy V3\msdeploy.exe";

# create the .nuget folder if it doesn't exist
if (!(Test-Path $nugetPath)) {
    mkdir -Path $nugetPath;
}

# download the nuget binary if it doesn't exist
if (!(Test-Path $targetNugetExe)) {
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe;
}

# install nuget packages
& $targetNugetExe install "$siteCodeFolder\packages.config" -OutputDirectory $nugetPackagesPath;

# copy binaries to bin folder
if (!(Test-Path $binPath)) {
    mkdir -Path $binPath;
}
Get-ChildItem -Path $nugetPackagesPath -Recurse | Where-Object { $_.FullName -match "\\lib\\net4.*\\.*\.dll" } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $binPath;
}

# locate the Xdt dll
$xdtPath = (Get-ChildItem -Path $nugetPackagesPath -Include 'Microsoft.Web.XmlTransform.dll' -Recurse) | Select-Object -Last 1;
if (!$xdtPath) { throw 'Microsoft.Web.XmlTransform.dll not found' };

# load the Xdt dll
Add-Type -Path $xdtPath.FullName;

# Transform config file
# https://gist.github.com/sayedihashimi/f1fdc4bfba74d398ec5b
Write-Host "Loading $sourceConfig";
$document = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument;
$document.PreserveWhitespace = $true;
$document.Load($sourceConfig);

Write-Host "Applying $transformConfig"
$transform = New-Object Microsoft.Web.XmlTransform.XmlTransformation($transformConfig);

$succeed = $transform.Apply($document);

if (-not $succeed) {
    throw ("Failed to apply transformation");
}

# if the target config exists, copy it to a backup
if (Test-Path $targetConfig) {
    Copy-Item -Path $targetConfig -Destination "$targetConfig.bak" -Force;
}

Write-Host "Saving $targetConfig"
$document.Save($targetConfig);

# create deployment package 
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd569054(v=ws.10)
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-r2-and-2008/dd569019(v=ws.10)
$arguments = @(
    "-verb:sync",
    "-source:iisApp=`"$siteCodeFolder`",includeAcls=false,enable32BitAppOnWin64=false,managedPipelineMode=Integrated,managedRuntimeVersion=`"v4.0`"",
    "-dest:package=`"$sitePackageFolder\source.zip`"",
    "-declareParamFile=`"$siteCodeFolder\parameters.xml`"",
    "-skip:objectName=filePath,absolutePath=`".*\\web.config.bak$`"",
    "-skip:objectName=filePath,absolutePath=`".*\\web.release.config$`"",
    "-skip:objectName=filePath,absolutePath=`".*\\nuget.config$`"",
    "-skip:objectName=filePath,absolutePath=`".*\\packages.config$`"",
    "-skip:objectName=filePath,absolutePath=`".*\\parameters.xml$`""
);
& $msdeploy $arguments;

# if backup file exists, restore the original config from backup
if (Test-Path "$targetConfig.bak") {
    Copy-Item -Path "$targetConfig.bak" -Destination $targetConfig -Force;
    Remove-Item -Path "$targetConfig.bak" -Force;
}
