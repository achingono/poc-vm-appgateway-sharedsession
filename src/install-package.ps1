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
# download redis-com-client-master.zip
Invoke-WebRequest https://gitlab.com/erik4/redis-com-client/-/archive/master/redis-com-client-master.zip?path=Precompiled%20DLLs -OutFile redis-com-client-master.zip
# unzip redis-com-client-master.zip
Expand-Archive -Path redis-com-client-master.zip -DestinationPath ./bin
# register redis-com-client.dll
# https://gitlab.com/erik4/redis-com-client/-/tree/master?ref_type=heads#installation
& c:\Windows\Microsoft.NET\Framework64\v4.0.30319\regasm .\bin\redis-com-client.dll /tlb:redis-com-client.tlb /codebase 