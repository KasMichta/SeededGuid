#requires -modules InvokeBuild

Param (
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SourceLocation,
    [String]
    $RepoName = 'PSGallery'
)

Set-StrictMode -Version Latest

task . Clean, Build

Enter-Build {

    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Force
    }
    Import-Module -Name PSDepend -Force

    Invoke-PSDepend -Force

    $script:moduleName = 'SeededGuid'
    $script:moduleSourcePath = Join-Path -Path $BuildRoot -ChildPath $moduleName
    $script:moduleManifestPath = Join-Path -Path $moduleSourcePath -ChildPath "$moduleName.psd1"
    $script:nuspecPath = Join-Path -Path $moduleSourcePath -ChildPath "$moduleName.nuspec"
    $script:buildOutputPath = Join-Path -Path $BuildRoot -ChildPath 'build'

    $script:newModuleVersion = New-Object -TypeName System.Version -ArgumentList (1, 0, 0)

    $script:functionsToExport = (Test-ModuleManifest $moduleManifestPath).ExportedFunctions
}

task Analyse {
    
    $testFiles = Get-ChildItem -Path $moduleSourcePath -Recurse -Include "*.PSSATests.*"

    $config = New-PesterConfiguration @{
        Run = @{
            Path = $testFiles
            Exit = $true
        }
        TestResult =@{
            Enabled = $true
        }
    }
    
    Invoke-Pester -Configuration $config
}

task Test {

    $testFiles = Get-ChildItem -Path $moduleSourcePath -Recurse -Include "*.Tests.*"

    $config = New-PesterConfiguration @{
        Run = @{
            Path = $testFiles
            Exit = $true
        }
        TestResult = @{
            Enabled = $true
        }
    }

    Invoke-Pester -Configuration $config
}

# Increments Minor Version for each new function, otherwise increments Build Version
task GenerateNewModuleVersion {

    $existingPackage = $null

    try {
        $existingPackage = Find-Module -Repository $repoName -Name $moduleName
    } catch {
        throw "Failed to find $moduleName in $repoName repository"
    }

    if ($existingPackage) {
        $currVersion = New-Object System.Version($existingPackage.Version)
        [int]$major = $currVersion.Major
        [int]$minor = $currVersion.Minor
        [int]$build = $currVersion.Build

        $existingFunctionsCount = $existingPackage.Includes.Function.Count

        [int]$sourceFunctionsCount = (Get-ChildItem -Path "$moduleSourcePath\Public\*.ps1" -Exclude "*.Tests.*" -Recurse | Measure-Object).Count
        [int]$newFunctionsCount = [System.Math]::Abs($sourceFunctionsCount - $existingFunctionsCount)

        if ($newFunctionsCount -gt 0) {
            [int]$Minor ++
            [int]$Build = 0
        } else {
            [int]$Build ++
        }

        $script:newModuleVersion = New-Object -TypeName System.Version -ArgumentList ($Major, $Minor, $Build)
    }

}

# Generates a list of functions to export from the module
task GenerateListOfFunctionsToExport {

    $params = @{
        Force = $true
        PassThru = $true
        Name = (Resolve-Path (Get-ChildItem -Path $moduleSourcePath -Filter '*.psm1')).Path
    }

    $Powershell = [powershell]::Create()

    [void]$Powershell.AddScript({
            Param ($Name, $PassThru, $Force)
            $module = Import-Module -Name $Name -PassThru:$PassThru -Force:$Force
            $module | Where-Object {$_.Path -notin $module.scripts}
        }).AddParameters($Params)

    $module = $Powershell.Invoke()
    $script:functionsToExport = $module.ExportedFunctions.keys
}

# Updates the module manifest with the new version and list of functions to export
task UpdateModuleManifest GenerateNewModuleVersion, GenerateListOfFunctionsToExport, {
    $params = @{
        Path = $moduleManifestPath
        FunctionsToExport = $functionsToExport
        ModuleVersion = $newModuleVersion
    }

    Update-ModuleManifest @params
}

# Updates the nuget package specification with the new module version
task UpdatePackageSpecification GenerateNewModuleVersion, {
    $xml = New-Object -TypeName 'XML'
    $xml.Load($nuspecPath)

    $metaData = Select-Xml -Xml $xml -XPath '//package/metadata'
    $metaData.Node.Version = $newModuleVersion

    $xml.save($nuspecPath)
}

# Builds the module after updating the module manifest and package specification
task Build UpdateModuleManifest, UpdatePackageSpecification, {

    if (-not (Test-Path $buildOutputPath)) {
        New-Item -Path $buildOutputPath -ItemType Directory
    }

    $Params = @{
        Path = Join-Path -path $BuildRoot -ChildPath $moduleName
        Destination = $buildOutputPath
        Exclude = "*.Tests.*", "*.PSSATests.*"
        Recurse = $true
        Force = $true
    }

    Copy-Item @Params
}


task Clean {
    if (Test-Path -Path $buildOutputPath) {
        Remove-Item -Path $buildOutputPath -Recurse
    }
}
