# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

param (
    [Parameter(ParameterSetName="build")]
    [switch]
    $Clean,

    [Parameter(ParameterSetName="build")]
    [switch]
    $Build,

    [Parameter(ParameterSetName="build")]
    [switch]
    $Test,

    [Parameter(ParameterSetName="build")]
    [string[]]
    [ValidateSet("Functional","StaticAnalysis")]
    $TestType = @("Functional"),

    [Parameter(ParameterSetName="help")]
    [switch]
    $UpdateHelp
)

$config = Get-PSPackageProjectConfiguration -ConfigPath $PSScriptRoot

$script:ModuleName = $config.ModuleName
$script:SrcPath = $config.SourcePath
$script:OutDirectory = $config.BuildOutputPath
$script:TestPath = $config.TestPath

$script:ModuleRoot = Join-Path $PSScriptRoot $SrcPath
$script:Culture = $config.Culture

<#
.DESCRIPTION
Implement build and packaging of the package and place the output $OutDirectory/$ModuleName
#>
function DoBuild
{
    Write-Verbose -Verbose "Starting DoBuild"

    Write-Verbose -Verbose "Copying module files to '${OutDirectory}/${ModuleName}'"
    # copy psm1 and psd1 files
    copy-item "${SrcPath}/${ModuleName}.psd1" "${OutDirectory}/${ModuleName}"
    copy-item "${SrcPath}/*.psm1" "${OutDirectory}/${ModuleName}"
    copy-item "${SrcPath}/*.ps1xml" "${OutDirectory}/${ModuleName}"
    copy-item "${SrcPath}/*.ps1" "${OutDirectory}/${ModuleName}"
    # copy format files here
    #

    # copy help
    Write-Verbose -Verbose "Copying help files to '${OutDirectory}/${ModuleName}'"
    copy-item -Recurse "${SrcPath}/help/${Culture}" "${OutDirectory}/${ModuleName}"

    if ( Test-Path "${SrcPath}/code" ) {
        Write-Verbose -Verbose "Building assembly and copying to '${OutDirectory}/${ModuleName}'"
        # build code and place it in the staging location
        try {
            Push-Location "${SrcPath}/code"
            $result = dotnet publish
            copy-item "bin/Debug/netstandard2.0/publish/${ModuleName}.dll" "../../${OutDirectory}/${ModuleName}"
        }
        catch {
            $result | ForEach-Object { Write-Warning $_ }
            Write-Error "dotnet build failed"
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Verbose -Verbose "No code to build in '${SrcPath}/code'"
    }

    ## Add build and packaging here
    Write-Verbose -Verbose "Ending DoBuild"
}

if ( ! ( Get-Module -ErrorAction SilentlyContinue PSPackageProject) ) {
    Install-Module PSPackageProject
}

if ($Clean -and (Test-Path $OutDirectory))
{
    Remove-Item -Force -Recurse $OutDirectory -ErrorAction Stop -Verbose
}

if (-not (Test-Path $OutDirectory))
{
    $script:OutModule = New-Item -ItemType Directory -Path (Join-Path $OutDirectory $ModuleName)
}
else
{
    $script:OutModule = Join-Path $OutDirectory $ModuleName
}

if ($Build.IsPresent)
{
    $sb = (Get-Item Function:DoBuild).ScriptBlock
    Invoke-PSPackageProjectBuild -BuildScript $sb
}

if ( $Test.IsPresent ) {
    Invoke-PSPackageProjectTest -Type $TestType
}
