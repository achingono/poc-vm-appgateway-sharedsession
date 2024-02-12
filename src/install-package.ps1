# download the nuget binary
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = ".\nuget\nuget.exe"
mkdir -Path "nuget"
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
Set-Alias nuget $targetNugetExe -Scope Global -Verbose
# install nuget package
nuget install Microsoft.Web.RedisSessionStateProvider -OutputDirectory ./packages -Framework net46
# copy binaries to bin folder
Get-ChildItem -Path ./packages -Recurse | Where-Object { $_.FullName -match "\\lib\\net4.*\\.*\.dll"} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination ./bin
}