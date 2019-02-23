using module .\support.psm1
using module .\bugsnag.psm1

Trace-VstsEnteringInvocation $MyInvocation

$jsonFile = Get-VstsInput -Name JsonFile -Require
$propertyPath = Get-VstsInput -Name PropertyPath -Require
$versionMask = Get-VstsInput -Name VersionMask -Require

$versionVariable = Get-VstsInput -Name VersionVariable -Require

# Notification Settings
$notifyBugsnag = Get-VstsInput -Name NotifyBugsnag -AsBool
$bugsnagUrl = Get-VstsInput -Name BugsnagUrl
$bugsnagApiKey = Get-VstsInput -Name BugsnagApiKey
$bugsnagBuilderName = Get-VstsInput -Name BugsnagBuilderName
$bugsnagReleaseStage = Get-VstsInput -Name BugsnagReleaseStage
$bugsnagAutoAssignRelease = Get-VstsInput -Name BugsnagAutoAssignRelease -AsBool
$bugsnagSourceControl = Get-VstsInput -Name BugsnagSourceControl -AsBool
$bugsnagSCProvider = Get-VstsInput -Name BugsnagSCProvider
$bugsnagSCRepo = Get-VstsInput -Name BugsnagSCRepo
$bugsnagSCRevision = Get-VstsInput -Name BugsnagSCRevision

$devOpsPAT = Get-VstsInput -Name DevOpsPAT -Require
$devOpsUri = $env:SYSTEM_TEAMFOUNDATIONSERVERURI
$projectName = $env:SYSTEM_TEAMPROJECT
$projectId = $env:SYSTEM_TEAMPROJECTID 
$buildId = $env:BUILD_BUILDID

# ###########################################################################
# ###########################################################################

Write-Output "JSONFile               : $($jsonFile)"
Write-Output "BugsnagProperty        : $($propertyPath)"
Write-Output "VersionMask            : $($versionMask)"
Write-Host "=============================================================================="
$notify = BoolToYesNo $notifyBugsnag
Write-Output "Notify Bugsnag         : $($notify)" 
if ($notifyBugsnag) {
    Write-Output "Notify Url             : $($bugsnagUrl)"
    Write-Output "Api Key                : $(if (![System.String]::IsNullOrWhiteSpace($bugsnagApiKey)) { '***'; } else { '<not present>'; })"
    Write-Output "Builder Name           : $($bugsnagBuilderName)"
    Write-Output "Release Stage          : $($bugsnagReleaseStage)"
    $autoAssign = BoolToYesNo $bugsnagAutoAssignRelease
    Write-Output "Auto Assign Release    : $($autoAssign)"
    $sourceControl = BoolToYesNo $bugsnagSourceControl
    Write-Output "Source Control         : $($sourceControl)"
    if ($bugsnagSourceControl) {
        Write-Output "- Provider             : $($bugsnagSCProvider)"
        Write-Output "- Repo                 : $($bugsnagSCRepo)"
        Write-Output "- Revision             : $($bugsnagSCRevision)"
    }
}
Write-Host "=============================================================================="
Write-Output "VersionVariable        : $($versionVariable)"
Write-Output "DevOps PAT             : $(if (![System.String]::IsNullOrWhiteSpace($devOpsPAT)) { '***'; } else { '<not present>'; })"
Write-Output "DevOps Uri             : $($devOpsUri)"
Write-Output "Project Name           : $($projectName)"
Write-Output "Project Id             : $($projectId)"
Write-Output "BuildId                : $($buildId)"
Write-Host "=============================================================================="

# ###########################################################################
# ###########################################################################

# ---------------------------------------------------------------- Setup Notify Args

$bugsnagArgs = ParseBugsnagArgs $bugsnagUrl $bugsnagApiKey $bugsnagBuilderName $bugsnagReleaseStage $bugsnagAutoAssignRelease $bugsnagSourceControl $bugsnagSCProvider $bugsnagSCRepo $bugsnagSCRevision

# ---------------------------------------------------------------- Check Json File

if (!([System.IO.File]::Exists($jsonFile))) {
    Write-Error "Your json file cannot be found at the specified location: $($jsonFile)"
    exit 0
}

if ($null -eq $propertyPath -or $propertyPath.length -lt 1) {
    Write-Error "Please specify a property path."
    exit 0
}

# ---------------------------------------------------------------- Parse File Version

$jsonInput = Get-Content $jsonFile | Out-String | ConvertFrom-Json

$jsonFileValue = Invoke-Expression "`$jsonInput.$propertyPath" 

if ($null -eq $jsonFileValue) {
    Write-Warning "The current value at path '$($propertyPath)' is null. This indicates the property may not exist. Using 0.0.0.";
    $jsonFileValue = "0.0.0"
}
else {
    Write-Host "Current value at '$propertyPath': $jsonFileValue";
}

# ---------------------------------------------------------------- Validate File Version

$fileArray = ValidateVersionString($jsonFileValue)

Write-Host "Validate Json Value: Ok"

# ---------------------------------------------------------------- Validate Mask Version

Write-Host "Current Mask Value: $versionMask";

$maskArray = ValidateVersionMaskString($versionMask)    

Write-Host "Validate Mask: Ok"

# ---------------------------------------------------------------- DevOps Load Version Variable

$buildUri = "$($devOpsUri)$($projectName)/_apis/build/builds/$($buildId)?api-version=4.1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $devOpsPAT)))
$devOpsHeader = @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

Write-Host "Attempting to retrieve build at: $($buildUri)."

try {
    $buildDef = Invoke-RestMethod -Uri $buildUri -Method Get -ContentType "application/json" -Headers $devOpsHeader    
}
catch {
    Write-Host "Retrieve build: Failed"
    Write-Error $_.Exception.Message
    exit 0
}

if (-not ($buildDef -and $buildDef.definition)) {
    Write-Error "Unexpected response from Azure DevOps Api. Please check your parameters including your PAT."
    exit 0
}

Write-Host "Retrieve build: Success"

$definitionId = $buildDef.definition.id
$defUri = "$($devOpsUri)$($projectName)/_apis/build/definitions/$($definitionId)?api-version=4.1"

Write-Host "Attempting to retrieve the build definition at: $($defUri)."
try {
    $definition = Invoke-RestMethod -Method Get -Uri $defUri -Headers $devOpsHeader -ContentType "application/json"    
    Write-Host "Retrieve build definition: Success";
}
catch {
    Write-Host "Retrieve build definition: Failed";
    Write-Error $_.Exception.Message
    exit 0
}

# ---------------------------------------------------------------- Validate Version Variable

$storedVersionString = $definition.variables.$VersionVariable.Value

Write-Host "Validate '$versionVariable': $storedVersionString"

$storedArray = ValidateVersionString($storedVersionString)

Write-Host "Validate '$versionVariable': Ok"

# ---------------------------------------------------------------- Create Session Objects

$storedVersion = [Mask]::new($storedArray[0], $storedArray[1], $storedArray[2])
$maskVersion = [Mask]::new($maskArray[0], $maskArray[1], $maskArray[2])
$fileVersion = [Mask]::new($fileArray[0], $fileArray[1], $fileArray[2])

$sessionMask = MergeMask $maskVersion $fileVersion
$sessionMaskString = "$($sessionMask.Major).$($sessionMask.Minor).$($sessionMask.Patch)"

# ---------------------------------------------------------------- Generate Next Version

$newVersion = GenerateNextVersion $sessionMask $storedVersion

$newVersionValue = "$($newVersion.Major).$($newVersion.Minor).$($newVersion.Patch)";

$bugsnagArgs.AppVersion = $newVersionValue

Write-Host "New version generated: $newVersionValue";

# ---------------------------------------------------------------- Display Info

Write-Host "=============================================================================="

Write-Host "> Version Pattern: $($sessionMaskString)" -ForegroundColor Cyan
Write-Host "-> Current version: $($storedVersionString) (version variable)" -ForegroundColor Yellow
Write-Host "--> New Version: $($newVersionValue)" -ForegroundColor Green
Write-Host "---> Replacing '$($jsonFileValue)' with '$($newVersionValue)' at '$($propertyPath)'"

Write-Host "=============================================================================="

# ---------------------------------------------------------------- Update Json

try {
    Invoke-Expression "`$jsonInput.$propertyPath = `$newVersionValue"
}
catch {
    Write-Error "Sorry about that old bean. It seems there is a problem setting a value at '$($propertyPath)'. Please check to ensure this path exists.";
    exit 0;
}

# ---------------------------------------------------------------- Save Json Back To File

Write-Host "Writing json data back to file: '$($jsonFile)'"

$jsonOutput = $jsonInput  | ConvertTo-Json -Depth 50 -Compress |  ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }

Set-Content -Path $jsonFile -Value $jsonOutput

Write-Host "File updated."

# ---------------------------------------------------------------- Notify Bugsnag

if ($notifyBugsnag) {

    Write-Host "============================================================================== Notify Bugsnag"

    Write-Output "Builder Name           : $($bugsnagBuilderName)"
    Write-Output "Release Stage          : $($bugsnagReleaseStage)"
    Write-Output "App Version            : $($newVersionValue)"

    Write-Host "Attempting to notifying Bugsnag of build at: $bugsnagUrl"
  
    $result = NotifyBugsnag $bugsnagUrl $bugsnagArgs

    if ($result -eq $false) { exit 0 }
}

# ---------------------------------------------------------------- Save DevOps Build Definition 

Write-Host "============================================================================== Update Build Definition"

if ($storedVersionString -eq $newVersionValue) {
    Write-Host "VersionVariable '$versionVariable' value hasn't changed. Skipping DevOps build definition update" -ForegroundColor Yellow
    exit 1
}
else {
    $definition.variables.$VersionVariable.Value = $newVersionValue

    $definitionJson = $definition | ConvertTo-Json -Depth 50 -Compress
        
    Write-Host "Attempting to update build definition at: $($defUri)."

    try {
        Invoke-RestMethod -Method Put -Uri $defUri -Headers $devOpsHeader -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($definitionJson)) | Out-Null        
        Write-Host "Update build definition: Success"
    }
    catch {
        Write-Host "Update build definition: Failed"
        Write-Error $_.Exception.Message
        exit 0
    }
}



