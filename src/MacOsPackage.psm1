# Copyright (c) Travis Plunk. All rights reserved.
# Licensed under the MIT License.

$Script:FormulaName = 'Formula'
$Script:CaskName = 'Cask'

function Find-MacOsPackage
{
    param(
        [parameter(Mandatory)]
        [string] $Filter,
        [switch] $IncludeVersion
    )
    $results = Start-NativeExecution -ScriptBlock {
            brew search $Filter  2> $null
        } -IgnoreExitcode

    $type = $null
    $results | ForEach-Object {
        if($_ -like '==>*')
        {
            switch ($_)
            {
                '==> Casks'{
                    $type = $Script:CaskName
                }
                '==> Formulae'{
                    $type = $Script:FormulaName
                }
            }
        }
        elseif($_ -and $type)
        {
            $version = $null
            if($IncludeVersion.IsPresent)
            {
                $version = Get-MacOsPackageVersion -Name $_ -Type $type
            }
            [MacOsPackage]@{
                Name = $_
                Type = $type
                Version = $version
            }
        }
    }
}

function Get-MacOsPackage
{
    Get-MacOsPackageFormulae
    Get-MacOsPackageCask
}

function Get-MacOsPackageFormulae
{
    brew list --full-name --versions -1  2> $null | ForEach-Object {
        $name , $version = $_ -split ' '
        [MacOsPackage]@{
            Name = $name
            Version = $version
            Type = $Script:FormulaName
        }
    }
}

function Get-MacOsPackageCask
{
    brew cask list -1  2> $null | ForEach-Object {
        $name = $_
        Write-Verbose -Message "getting version info for $name ..."
        $version = Get-MacOsCaskVersion -Name $name
        Write-Verbose -Message "creating object for for $name ..."
        [MacOsPackage]@{
            Name = $name
            Version = $version
            Type = $Script:CaskName
        }
    }
}

Function Get-MacOsPackageVersion
{
    param(
        [string]$Name,
        [ValidateSet('Cask','Formula')]
        [string]$Type
    )
    switch($Type)
    {
        $Script:FormulaName {
            return Get-MacOsFormulaeVersion -Name $Name
        }
        $Script:CaskName{
            return Get-MacOsCaskVersion -Name $Name
        }
        default {
            throw "Unexpected package type $Type"
        }
    }
}

Function Get-MacOsCaskVersion
{
    param(
        [string]$Name
    )
    $info = brew cask info $name  2> $null
    $null, $details = $info[0] -split ': '
    $version,$updateInfo = $details -split '[ \(\)]{1,2}'
    Write-Verbose -Message "v:$version; ui:$updateInfo"
    return $version
}

Function Get-MacOsFormulaeVersion
{
    param(
        [string]$Name
    )

    $info = brew info $name 2> $null
    $null, $details = $info[0] -split ': '
    $channel, $version, $type = $details -split '[ ,\(\)\[\]]{1,3}'
    Write-Verbose -Message "c:$channel; v:$version; t:$type"
    return $version
}


# this function wraps native command Execution
# for more information, read https://mnaoumov.wordpress.com/2015/01/11/execution-of-external-commands-in-powershell-done-right/
# Also from https://github.com/PowerShell/PowerShell/blob/master/build.psm1
function Start-NativeExecution
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Low")]
    param(
        [scriptblock]$ScriptBlock,
        [switch]$IgnoreExitcode,
        [switch]$VerboseOutputOnError
    )
    $backupEAP = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    try {
        if ($PSCmdlet.ShouldProcess('Start-NativeExecution', "Execute "+$ScriptBlock.ToString())) {
            if($VerboseOutputOnError.IsPresent)
            {
                $output = & $ScriptBlock 2>&1
            }
            else
            {
                & $ScriptBlock
            }

            # note, if $ScriptBlock doesn't have a native invocation, $LASTEXITCODE will
            # point to the obsolete value
            if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
                if($VerboseOutputOnError.IsPresent -and $output)
                {
                    $output | Out-String | Write-Verbose -Verbose
                }

                # Get caller location for easier debugging
                $caller = Get-PSCallStack -ErrorAction SilentlyContinue
                if($caller)
                {
                    $callerLocationParts = $caller[1].Location -split ":\s*line\s*"
                    $callerFile = $callerLocationParts[0]
                    $callerLine = $callerLocationParts[1]

                    $errorMessage = "Execution of {$sb} by ${callerFile}: line $callerLine failed with exit code $LASTEXITCODE"
                    throw $errorMessage
                }
                throw "Execution of {$sb} failed with exit code $LASTEXITCODE"
            }
        }
    } finally {
        $script:ErrorActionPreference = $backupEAP
    }
}

Export-ModuleMember -function @(
    'Find-MacOsPackage'
    'Get-MacOsPackage'
)
