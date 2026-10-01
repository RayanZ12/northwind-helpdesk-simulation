<#
.SYNOPSIS
    Helpers to run commands on the Northwind lab VMs from the host.
.DESCRIPTION
    Dot-source this file. Uses WinRM through NAT Network port forwarding
    (127.0.0.1:55985/55986/55987) with Negotiate auth — Basic auth fails for
    domain accounts on member servers (see PROJECT-NOTES.md section 6).
.EXAMPLE
    . .\scripts\Connect-Lab.ps1
    Invoke-Lab -Vm DC01 -ScriptBlock { Search-ADAccount -LockedOut }
    Invoke-Help01 'sudo systemctl status apache2'
#>

. (Join-Path $PSScriptRoot 'Import-DotEnv.ps1')

$script:LabPorts = @{ DC01 = 55985; FS01 = 55986; CL01 = 55987 }

function Get-LabCredential {
    $cfg = Import-DotEnv
    if (-not $cfg['LAB_ADMIN_USER'] -or -not $cfg['LAB_ADMIN_PASSWORD']) {
        throw 'LAB_ADMIN_USER / LAB_ADMIN_PASSWORD missing in .env.'
    }
    $sec = ConvertTo-SecureString $cfg['LAB_ADMIN_PASSWORD'] -AsPlainText -Force
    New-Object System.Management.Automation.PSCredential($cfg['LAB_ADMIN_USER'], $sec)
}

function Invoke-Lab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('DC01','FS01','CL01')] [string]$Vm,
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList
    )
    Invoke-Command -ComputerName 127.0.0.1 -Port $script:LabPorts[$Vm] `
        -Credential (Get-LabCredential) -Authentication Negotiate `
        -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
}

function Test-Lab {
    foreach ($vm in $script:LabPorts.Keys) {
        try {
            $name = Invoke-Lab -Vm $vm -ScriptBlock { hostname } -ErrorAction Stop
            [pscustomobject]@{ VM = $vm; Status = 'OK'; Detail = $name }
        } catch {
            [pscustomobject]@{ VM = $vm; Status = 'FAIL'; Detail = $_.Exception.Message }
        }
    }
    try {
        $h = Invoke-Help01 'hostname'
        [pscustomobject]@{ VM = 'HELP01'; Status = 'OK'; Detail = $h }
    } catch {
        [pscustomobject]@{ VM = 'HELP01'; Status = 'FAIL'; Detail = $_.Exception.Message }
    }
}

function Invoke-Help01 {
    param([Parameter(Mandatory)] [string]$Command)
    $cfg  = Import-DotEnv
    $user = if ($cfg['UBUNTU_USER']) { $cfg['UBUNTU_USER'] } else { 'sysadmin' }
    $keyPath = if ($cfg['SSH_KEY_PATH']) { $cfg['SSH_KEY_PATH'] } else { '~/.ssh/northwind_ed25519' }
    $keyPath = $keyPath -replace '^~', $HOME
    & ssh -i $keyPath -p 2222 -o BatchMode=yes "$user@127.0.0.1" $Command
    if ($LASTEXITCODE -ne 0) { throw "SSH command failed (exit $LASTEXITCODE)." }
}
