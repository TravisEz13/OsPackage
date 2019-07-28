# Copyright (c) Travis Plunk. All rights reserved.
# Licensed under the MIT License.

Describe 'Find-OsPackage' -Tag 'CI' {
    it 'Should find powershell cask' {
        $results = Find-OsPackage -Filter powershell
        $results.Count | Should -BeGreaterOrEqual 1
        foreach ($result in $results) {
            $result.GetType().FullName | Should -Be 'MacOsCaskPackage'
            $result.Name | Should -BeLike '*powershell*'
            $result.Version | Should -BeNullOrEmpty
            $result.Type | Should -BeExactly 'Cask'
        }
    }
    it 'Should get the version of powershell cask' {
        $results = Find-OsPackage -Filter powershell -IncludeVersion
        $results.Count | Should -BeGreaterOrEqual 1
        $powershell = $results | Where-Object {$_.Name -eq 'powershell'}
        $powershell.Version | Should -Match '\d+.\d+.\d+'
    }

    it 'Should find cmake Formula' {
        $results = Find-OsPackage -Filter cmake
        $results.Count | Should -BeGreaterOrEqual 1
        foreach ($result in $results) {
            $result.GetType().FullName | Should -Match 'MacOs(Formula|Cask)Package'
            $result.Name | Should -BeLike '*cmake*'
            $result.Version | Should -BeNullOrEmpty
        }
        $notCask = @($results | Where-Object {$_.Type -ne 'Cask'})
        $notCask.Count | Should -BeGreaterThan 0
    }
    it 'Should get the version of cmake formula' {
        $results = Find-OsPackage -Filter cmake -IncludeVersion
        $results.Count | Should -BeGreaterOrEqual 1
        $cmake = $results | Where-Object {$_.Name -eq 'cmake' -and $_.Type -eq 'Formula'}
        $cmake.Version | Should -Match '\d+.\d+.\d+'
    }
}

Describe 'Get-OsPackage' -Tag 'CI' {
    BeforeAll {
        $packageList = Get-OsPackage
    }
    it "Should find at least one formula" {
        $formula = $packageList | Where-Object {$_.Type -eq 'Formula'}
        $formula.Count | Should -BeGreaterOrEqual 1
        foreach ($result in $formula) {
            $result.GetType().FullName | Should -Be 'MacOsFormulaPackage'
            $result.Type | Should -BeExactly "Formula"
            $result.Version | Should -Not -BeNullOrEmpty
        }
    }
    it "Should find powershell cask" {
        $powershell = $packageList | Where-Object {$_.Name -eq 'powershell'}
        $powershell.Count | Should -Be 1
        $powershell.Type | Should -BeExactly "Cask"
        $powershell.Version | Should -Match '\d+.\d+.\d+'
    }
}

Describe 'Install-OsPackage' -Tag 'CI' {
    BeforeAll {
        $testCases = @(
            @{
                Type='formula'
                Name='htop'
                Command='htop'
            }
            @{
                Type='cask'
                Name='beyond-compare'
                Command='bcomp'
            }
        )
    }
    it "Should install the <Name> <Type>" -TestCases $testCases {
        param(
            [parameter(Mandatory)]
            [string]$Name,

            [parameter(Mandatory)]
            [string]$Command,
            [String]$Type
        )
        Get-Command -Name $Command -ErrorAction Ignore | Should -BeNullOrEmpty
        Install-OsPackage -Name $Name
        Get-Command -Name $Command -ErrorAction Ignore | Should -Not -BeNullOrEmpty
    }
}