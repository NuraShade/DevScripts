param(
    [Parameter(Mandatory = $true)]
    [string]$FolderPath
)

if (!(Test-Path $FolderPath)) {
    Write-Host "Folder not found: $FolderPath" -ForegroundColor Red
    exit
}

Add-Type -AssemblyName System.Drawing

$extensions = '*.png','*.jpg','*.jpeg','*.bmp'

$outputFolder = Join-Path $FolderPath "ICO"
if (!(Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

foreach ($ext in $extensions) {
    foreach ($file in Get-ChildItem $FolderPath -Filter $ext) {

        $base = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
        $icoPath = Join-Path $outputFolder "$base.ico"

        # Load and resize
        $src = [System.Drawing.Image]::FromFile($file.FullName)
        $bmp = New-Object System.Drawing.Bitmap 48,48
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.DrawImage($src,0,0,48,48)
        $gfx.Dispose()
        $src.Dispose()

        # Convert resized bitmap → PNG byte array
        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $ms.ToArray()
        $ms.Dispose()
        $bmp.Dispose()

        # Build ICO file manually
        $fs = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
        $bw = New-Object System.IO.BinaryWriter($fs)

        # ICON HEADER
        $bw.Write([UInt16]0)       # reserved
        $bw.Write([UInt16]1)       # type = icon
        $bw.Write([UInt16]1)       # number of images = 1

        # ICON DIRECTORY ENTRY
        $bw.Write([Byte]48)        # width
        $bw.Write([Byte]48)        # height
        $bw.Write([Byte]0)         # no palette
        $bw.Write([Byte]0)         # reserved
        $bw.Write([UInt16]1)       # color planes
        $bw.Write([UInt16]32)      # bits per pixel (PNG)
        $bw.Write([UInt32]$pngBytes.Length) # size
        $bw.Write([UInt32]22)      # offset (6 + 16)

        # IMAGE DATA
        $bw.Write($pngBytes)

        $bw.Close()
        $fs.Close()

        Write-Host "Created: $icoPath"
    }
}

Write-Host "Done!"
