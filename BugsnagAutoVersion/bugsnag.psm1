Class BugsnagArgs {
    [string]$Url
    [string]$ApiKey
    [string]$AppVersion
    [string]$BuilderName
    [string]$ReleaseStage
    [bool]$AutoAssignRelease
    [string]$SCProvider
    [string]$SCRepo
    [string]$SCRevision

    BugsnagArgs([string]$url, [string]$apiKey, [string]$builderName, 
        [string]$releaseStage, [bool]$autoAssignRelease) {
        
        $this.Url = $url
        $this.ApiKey = $apiKey
        $this.BuilderName = $builderName
        $this.ReleaseStage = $releaseStage
        $this.AutoAssignRelease = $autoAssignRelease
    }
}

function ParseBugsnagArgs {
    [CmdletBinding()]
    param([string]$url, [string]$apiKey, [string]$builderName, [string]$releaseStage, [bool]$autoAssignRelease, 
        [bool]$includeSourceControl, [string]$scProvider, [string]$scRepo, [string]$scRevision)

    $notifyArgs = [BugsnagArgs]::new($url, $apiKey, $builderName, $releaseStage, $autoAssignRelease)

    if ($includeSourceControl) {
        $notifyArgs.SCProvider = $scProvider
        $notifyArgs.SCRepo = $scRepo
        $notifyArgs.SCRevision = $scRevision
    }

    return $notifyArgs
}

function ValidateBugsnagArgs {
    [CmdletBinding()]
    param([BugsnagArgs]$bugsnagArgs)
    
    if($null -eq $bugsnagArgs) {
        Write-Error "Oops. You seem to have forgotton to pass any arguments. BugsnagArgs is null."
        return $false
     }

    if($null -eq $bugsnagArgs.ApiKey -or $bugsnagArgs.ApiKey.Length -eq 0) { 
        Write-Error "Your Bugsnag Api Key is required."
        return $false
    }

    if($null -eq $bugsnagArgs.AppVersion -or $bugsnagArgs.AppVersion.Length -eq 0) { 
        Write-Error "Your App Version is required."
        return $false
    }

    return $true
}

function GenerateBugsnagNotifyPayload {
    [CmdletBinding()]
    param([BugsnagArgs] $bugsnagArgs) 

    $argsHash = @{
        apiKey            = "$($bugsnagArgs.ApiKey)"
        appVersion        = "$($bugsnagArgs.AppVersion)"
        releaseStage      = "$($bugsnagArgs.ReleaseStage)"
        builderName       = "$($bugsnagArgs.BuilderName)"
        autoAssignRelease = $bugsnagArgs.AutoAssignRelease
        sourceControl     = @{
            provider   = "$($bugsnagArgs.SCProvider)"
            repository = "$($bugsnagArgs.SCRepo)"
            revision   = "$($bugsnagArgs.SCRevision)"
        }
        metadata          = @{}
    }

    $jsonOutput = $argsHash  | ConvertTo-Json -Depth 10 -Compress |  ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }

    return $jsonOutput
}

function NotifyBugsnag {
    [CmdletBinding()]
    param([string]$bugsnagUrl, [BugsnagArgs]$bugsnagArgs)

    $argsValid = ValidateBugsnagArgs $bugsnagArgs

    if ($argsValid -eq $false) { return $false}

    $notifyPayload = GenerateBugsnagNotifyPayload $bugsnagArgs

    try {
        Invoke-RestMethod -Method POST -Uri $bugsnagUrl -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($notifyPayload)) | Out-Null
        Write-Host "Notify Bugsnag: Success."    
    }
    catch {
        Write-Host "Notify Bugsnag: Failed."
        Write-Error $_.Exception.Message
        return $false
    }
    return $true
}

