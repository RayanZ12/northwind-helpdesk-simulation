<#
.SYNOPSIS
    Loads KEY=VALUE pairs from the project's .env file into a hashtable.
.DESCRIPTION
    Dot-source this file, then call Import-DotEnv. Values are trimmed; blank lines and
    lines starting with # are ignored. Secrets are never printed.
.EXAMPLE
    . "$PSScriptRoot\Import-DotEnv.ps1"
    $envVars = Import-DotEnv
    $envVars.OSTICKET_URL
#>
function Import-DotEnv {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent) '.env')
    )

    if (-not (Test-Path $Path)) {
        throw ".env not found at '$Path'. Copy .env.example to .env and fill it in."
    }

    $vars = @{}
    foreach ($line in Get-Content -Path $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        $idx = $trimmed.IndexOf('=')
        if ($idx -lt 1) { continue }
        $key   = $trimmed.Substring(0, $idx).Trim()
        $value = $trimmed.Substring($idx + 1).Trim()
        # Strip BOM, non-breaking spaces and zero-width characters picked up by copy-paste
        $value = $value -replace '[\uFEFF\u00A0\u200B-\u200D]', ''
        $vars[$key] = $value
    }
    return $vars
}
