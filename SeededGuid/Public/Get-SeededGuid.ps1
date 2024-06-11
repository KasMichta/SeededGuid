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
