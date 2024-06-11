BeforeAll {
    $here = Split-Path -Parent $PSCommandPath

    $modulePath = "$($PSCommandPath -replace '\.Tests\.ps1$', '').psm1"
    $moduleName = ((Split-Path -Leaf $modulePath) -replace '.psm1')
    @(Get-Module -Name $moduleName).Where({$_.version -ne '0.0'}) | Remove-Module
    Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe "'$moduleName' Module Tests" {

    Context 'Module Configuration' {

        It 'Should have root module' {
            Test-Path $modulePath | Should -Be $true
        }

        It 'Should have manifest' {
            Test-Path "$here\$moduleName.psd1" | Should -Be $true
        }

        It 'Should have public functions' {
            Test-Path "$here\Public\*.ps1" | Should -Be $true
        }

        It 'Should be valid code' {
            $file = Get-Content -Path $modulePath -ErrorAction Stop
            $errors = $null
            [void] [System.Management.Automation.PSParser]::Tokenize($file, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Module Import/Removal' {
        It 'Should Import without error' {
            Get-Module -Name $moduleName | Should -Not -BeNullOrEmpty
        }

        It 'Should Remove without error' {
            {Remove-Module -Name $moduleName -ErrorAction Stop} | Should -Not -Throw
            Get-Module -Name $moduleName | Should -BeNullOrEmpty
        }
    }
}
    
$here = Split-Path -Parent $PSCommandPath

$functionPaths = @()
if (Test-Path -Path "$here\Private\*.ps1") {
    $functionPaths += Get-ChildItem -Path "$here\Private\*.ps1" -Exclude "*.Tests.*"
}
if (Test-Path -Path "$here\Public\*.ps1") {
    $functionPaths += Get-ChildItem -Path "$here\Public\*.ps1" -Exclude "*.Tests.*"
}

Describe "'<_>' Function Tests" -ForEach $functionPaths {
    BeforeDiscovery {
        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Raw $_), [ref]$null, [ref]$null)
        $AbstractSearchDelegate = {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}
        $ParsedFunction = $AbstractSyntaxTree.Findall($AbstractSearchDelegate, $true) | Where-Object -Property Name -eq $_.BaseName

        $parameters = @($ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath.Foreach{$_.ToString()})
    }
        
    BeforeAll {
        $functionName = $_.BaseName
        $functionPath = $_
    }

    Context "Function Code Style Tests" {
        It "Should be advanced functioon" {
            $functionPath | Should -FileContentMatch 'Function'
            $functionPath | Should -FileContentMatch 'CmdletBinding'
            $functionPath | Should -FileContentMatch 'Param'
        }

        It "Should contain Write-Verbose blocks" {
            $functionPath | Should -FileContentMatch 'Write-Verbose'
        }

        It 'Should be valid code' {
            $file = Get-Content -Path $modulePath -ErrorAction Stop
            $errors = $null
            [void] [System.Management.Automation.PSParser]::Tokenize($file, [ref]$errors)
            $errors.Count | Should -Be 0
        }
            
        It 'Should have tests' {
            Test-Path ($functionPath -replace "\.ps1", ".Tests.ps1") | Should -Be $true
                ($functionPath -replace "\.ps1", ".Tests.ps1") | Should -FileContentMatch "Describe `"'$functionName'"
        }
    }
}

