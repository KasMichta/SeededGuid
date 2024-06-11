<#
.SYNOPSIS
    Generates a GUID from a seed string.
.DESCRIPTION
    This function generates a GUID from a seed string. The GUID is deterministic, meaning that the same seed will always produce the same GUID.
.PARAMETER Seed
    The seed string to generate the GUID from.
.INPUTS
    System.String
.OUTPUTS
    System.Guid
.EXAMPLE
    PS> Get-SeededGuid -Seed 'Hello, World!

    Guid
    ----
    98500190-d23c-b04f-d696-3f7d28e17f72
#>
Function Get-SeededGuid {
    [CmdletBinding()]
    [OutputType([guid])]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [string]
        $Seed
    )

    begin {
        Write-Verbose "Generating a new GUID from seed '$Seed'"
    }

    process {
        $stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($Seed))
        [guid] [System.Security.Cryptography.HashAlgorithm]::Create('MD5').ComputeHash($stream)
    }

    end {
        Write-Verbose "GUID generated"
    }
}
