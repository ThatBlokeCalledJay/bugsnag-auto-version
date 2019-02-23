
Class Version {
    [int32]$Major
    [int32]$Minor
    [int32]$Patch

    Version([int32]$major, [int32]$minor, [int32]$patch) {
        $this.Major = $major
        $this.Minor = $minor
        $this.Patch = $patch
    }
}

Class Mask {
    [string]$Major
    [string]$Minor
    [string]$Patch

    Mask([string]$major, [string]$minor, [string]$patch) {
        $this.Major = $major
        $this.Minor = $minor
        $this.Patch = $patch
    }
}

function GenerateNextVersion {
    [CmdletBinding()]
    param([Mask] $mask, [Mask] $version)

    # $mask is combination of mask and current file version.
    # $version is the current auto-value variable

    $resetMinor = $false
    $resetPatch = $false

    $newVersion = [Version]::new($version.Major, $version.Minor, $version.Patch)

    if ($mask.Major -eq "$") {
        $newVersion.Major ++
        $resetMinor = $true
        $resetPatch = $true
    }
    else {
        $maskMajor = [convert]::ToInt32($mask.Major, 10)

        if ($maskMajor -gt $newVersion.Major) {
            $resetPatch = $true
            $resetMinor = $true
        }

        if ($maskMajor -lt $newVersion.Major) {
            Write-Warning "Major downgrade detected"
        }

        $newVersion.Major = $maskMajor
    }

    if ($mask.Minor -eq "$") {
        if ($resetMinor) {
            $newVersion.Minor = 0
        }
        else {
            $newVersion.Minor ++
        }
        $resetPatch = $true
    }
    else {
        $maskMinor = [convert]::ToInt32($mask.Minor, 10)

        if ($maskMinor -gt $newVersion.Minor) {
            $resetPatch = $true
        }

        if ($maskMinor -lt $newVersion.Minor -and (-not $resetMinor)) {
            Write-Warning "Minor downgrade detected"
        }

        $newVersion.Minor = $maskMinor
    }

    if ($mask.Patch -eq "$") {
        if ($resetPatch) {
            $newVersion.Patch = 0
        }
        else {
            $newVersion.Patch ++
        }
    }
    else {
        $maskPatch = [convert]::ToInt32($mask.Patch, 10)

        if ($maskPatch -lt $newVersion.Patch -and (-not $resetPatch)) {
            Write-Warning "Patch downgrade detected"
        }

        $newVersion.Patch = $maskPatch
    }

    return $newVersion
}

function MergeMask {
    [CmdletBinding()]
    param([Mask] $mask, [Mask] $version)

    $merged = [Mask]::new($version.Major, $version.Minor, $version.Patch)

    if ($mask.Major -eq "$") {
        $merged.Major = "$"
    }
    
    if ($mask.Minor -eq "$") {
        $merged.Minor = "$"
    }

    if ($mask.Patch -eq "$") {
        $merged.Patch = "$"
    }

    return $merged
}

function BoolToYesNo([bool]$value) {
    $result = "No"
    if ($value) {
        $result = "Yes"
    }
    return $result
}

function ConvertToBoolean {
    param
    (
        [Parameter(Mandatory = $false)][string] $value
    )
    switch ($value) {
        "True" { return $true; }
        "true" { return $true; }
        1 { return $true; }
        "false" { return $false; }
        "False" { return $false; } 
        0 { return $false; }
    }
}

function ValidateVersionString {
    [CmdletBinding()]
    param([string]$version)

    $versionParts = $version.split('.')

    if ($versionParts.Count -gt 3 -or $versionParts.Count -lt 3) {
        Write-Error "Your version number needs to be in the following format 'X.X.X' where X is an integer. Expected 'X.X.X' but got '$($version)'"
        exit 0
    }
    
    if ($versionParts[2] -like '*-*') {
        Write-Error "Unsupported Value: Pre-release suffix isn't currently supportd. Expected 'X.X.X' but got '$($version)'."
        exit 0
    }

    $versionObject = [Mask]::new($versionParts[0], $versionParts[1], $versionParts[2])

    if (-not [string]($versionObject.Major -as [int])) {
        Write-Error "Unexpected major value. Expected integer but got '$($versionObject.Major)'"
        exit 0
    }

    if (-not [string]($versionObject.Minor -as [int])) {
        Write-Error "Unexpected minor value. Expected integer but got '$($versionObject.Minor)'"
        exit 0
    }

    if (-not [string]($versionObject.Patch -as [int])) {
        Write-Error "Unexpected patch value. Expected integer but got '$($versionObject.Patch)'"
        exit 0
    }

    return $versionParts
}
function ValidateVersionMaskString {
    [CmdletBinding()]
    param([string]$version)

    $versionParts = $version.split('.')

    if ($versionParts.Count -gt 3 -or $versionParts.Count -lt 3) {
        Write-Error "Your version mask needs to be in the following format 'X.X.X' where X is an integer or the $ symbol. Expected 'X.X.X' but got '$($version)'"
        exit 0
    }
    
    if ($versionParts[2] -like '*-*') {
        Write-Error "Unsupported Value: Pre-release suffix isn't currently supportd. Expected 'X.X.X' but got '$($version)'."
        exit 0
    }

    $versionObject = [Mask]::new($versionParts[0], $versionParts[1], $versionParts[2])

    if (-not($versionObject.Major -eq "$" -or [string]($versionObject.Major -as [int]))) {
        Write-Error "Unexpected major value. Expected integer but got '$($versionObject.Major)'"
        exit 0
    }

    if (-not($versionObject.Minor -eq "$" -or [string]($versionObject.Minor -as [int]))) {
        Write-Error "Unexpected minor value. Expected integer but got '$($versionObject.Minor)'"
        exit 0
    }

    if (-not($versionObject.Patch -eq "$" -or [string]($versionObject.Patch -as [int]))) {
        Write-Error "Unexpected patch value. Expected integer but got '$($versionObject.Patch)'"
        exit 0
    }
    
    return $versionParts
}


