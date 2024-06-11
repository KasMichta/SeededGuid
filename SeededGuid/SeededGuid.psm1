Set-StrictMode -Version Latest

$public = @(Get-ChildItem -Path $PSScriptRoot'\Public\*.ps1' -Recurse -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path $PSScriptRoot'\Private\*.ps1' -Recurse -ErrorAction SilentlyContinue)

foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "Could not import $($import.FullName): $_"
    }
}

Export-ModuleMember -function $public.BaseName
