<#
.SYNOPSIS
    Creates a ticket in osTicket through its REST API.
.DESCRIPTION
    Reads OSTICKET_URL and OSTICKET_API_KEY from .env. The API key must be allowed for the
    IP osTicket sees (192.168.10.1 through the NAT Network).
    Help topic can be passed as its numeric ID (Admin Panel > Manage > Help Topics).
.EXAMPLE
    .\scripts\New-OsTicket.ps1 -Name "Samuel Mensah" -Email "samuel.mensah@ad.northwind.ca" `
        -Subject "Can't log in" -Message "It says my password is wrong." -TopicId 2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] [string]$Email,
    [Parameter(Mandatory)] [string]$Subject,
    [Parameter(Mandatory)] [string]$Message,
    [int]$TopicId
)

. (Join-Path $PSScriptRoot 'Import-DotEnv.ps1')
$cfg = Import-DotEnv

$url = $cfg['OSTICKET_URL']
$key = $cfg['OSTICKET_API_KEY']
if (-not $url -or -not $key) { throw 'OSTICKET_URL or OSTICKET_API_KEY missing in .env.' }
if ($key -match '[^\x20-\x7E]') {
    throw 'OSTICKET_API_KEY contains a non-ASCII character. Retype it by hand in .env.'
}

$body = [ordered]@{
    alert   = $true
    autorespond = $false
    source  = 'API'
    name    = $Name
    email   = $Email
    subject = $Subject
    message = "data:text/plain;charset=utf-8,$Message"
}
if ($TopicId) { $body.topicId = $TopicId }

$json = $body | ConvertTo-Json
try {
    $ticketNumber = Invoke-RestMethod -Uri "$url/api/tickets.json" -Method Post `
        -Headers @{ 'X-API-Key' = $key } -Body ([Text.Encoding]::UTF8.GetBytes($json)) `
        -ContentType 'application/json; charset=utf-8'
    Write-Output "Ticket created: #$ticketNumber"
}
catch {
    Write-Error "osTicket API call failed: $($_.Exception.Message). If it says 'API key not found', check the key's IP in osTicket (System Logs show the IP actually seen)."
}
