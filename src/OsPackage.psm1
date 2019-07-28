# Copyright (c) Travis Plunk. All rights reserved.
# Licensed under the MIT License.
function Find-OsPackage
{
    param(
        [parameter(Mandatory)]
        [string] $Filter,
        [switch] $IncludeVersion
    )

    if($IsMacOS)
    {
        return Find-MacOsPackage @PSBoundParameters
    }
    else
    {
        throw "Unsuported Platform"
    }
}

function Install-OsPackage
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
    param(
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string] $Name,
        [parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string] $Type
    )

    Process {
        if ($PSCmdlet.ShouldProcess($Name, "Install")) {
            if($IsMacOS)
            {
                    Install-MacOsPackage @PSBoundParameters
            }
            else
            {
                throw "Unsuported Platform"
            }
        }
    }
}

function Get-OsPackage
{
    if($IsMacOS)
    {
        Get-MacOsPackage
    }
    else
    {
        throw "Unsuported Platform"
    }
}

$Script:nestedModules = @(
    'MacOsPackage'
)
function Import-NestedModules
{
    # Hack to get classes everywhere
    . "$psscriptroot\OsPackageClasses.ps1"
    foreach ($module in $Script:nestedModules) {
        # if this code is being called, we are first or force loaded
        # So, force load the nestedModules
        Import-Module "$psscriptroot\$module.psm1" -Force
    }
}

Import-NestedModules

Export-ModuleMember -function @(
    'Find-OsPackage'
    'Get-OsPackage'
    'Install-OsPackage'
)
