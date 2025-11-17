#usage .\Create-IncFiles.ps1 -FolderPath "D:\MyFolder" -Count 20
param(
    [Parameter(Mandatory = $true)]
    [string]$FolderPath,

    [Parameter(Mandatory = $true)]
    [int]$Count
)

# Ensure folder exists
if (-not (Test-Path $FolderPath)) {
    New-Item -ItemType Directory -Path $FolderPath | Out-Null
}

for ($i = 0; $i -le $Count; $i++) {
    $file = Join-Path $FolderPath "$i.inc"

    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
        Write-Host "Created: $file"
    } else {
        Write-Host "Exists:  $file (skipped)"
    }
}

Write-Host "`nDone! Created files from 0.inc to $Count.inc"
