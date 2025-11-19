# usage .\Resize-Images.ps1 "D:\Images"
param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# Load System.Drawing assembly
Add-Type -AssemblyName System.Drawing

# Define resolutions
$resolutions = @(1024, 512, 256, 128, 64, 48, 32,16)

# Supported image formats
$extensions = "*.png","*.jpg","*.jpeg","*.bmp"

# Process each image
foreach ($ext in $extensions) {
    foreach ($file in (Get-ChildItem -Path $FolderPath -Filter $ext)) {

        Write-Host "Processing $($file.Name)..."

        # Load image without locking the file
        $fileStream = [System.IO.File]::OpenRead($file.FullName)
        $img = [System.Drawing.Bitmap]::FromStream($fileStream)
        $fileStream.Close()

        # Get base name without extension
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $extension = $file.Extension

        # Create folder for this image
        $imageFolder = Join-Path $FolderPath $baseName
        if (-not (Test-Path $imageFolder)) {
            New-Item -ItemType Directory -Path $imageFolder | Out-Null
        }

        # Process each resolution
        foreach ($size in $resolutions) {

            # Create resized image
            $resized = New-Object System.Drawing.Bitmap($size, $size)
            $graphics = [System.Drawing.Graphics]::FromImage($resized)
            
            # High quality resize
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            
            $graphics.DrawImage($img, 0, 0, $size, $size)
            $graphics.Dispose()

            # Save with new name
            $newFileName = "${baseName}_${size}${extension}"
            $outputPath = Join-Path $imageFolder $newFileName
            
            $resized.Save($outputPath)
            $resized.Dispose()

            Write-Host "  Created: $baseName\$newFileName"
        }

        $img.Dispose()
        Write-Host "Completed $($file.Name)"
    }
}

Write-Host "Done!"
