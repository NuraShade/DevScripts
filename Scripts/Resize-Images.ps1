# Resize-Images.ps1
#Usage & "path/of/script" -FolderPath "destination/folder/path"
# This script resizes all images in a folder to 48x48 pixels using .NET

# Get current folder or ask user for path
param(
    [string]$FolderPath = "."
)

# Load .NET assembly for image processing
Add-Type -AssemblyName System.Drawing

# Check if folder exists
if (-not (Test-Path $FolderPath)) {
    Write-Host " Folder not found: $FolderPath"
    exit
}

# Get all supported image files
$images = Get-ChildItem -Path $FolderPath -Include *.png, *.jpg, *.jpeg, *.bmp, *.gif -Recurse

foreach ($img in $images) {
    try {
        # Load image into memory stream to avoid file lock
        $fileStream = [System.IO.File]::OpenRead($img.FullName)
        $bitmap = [System.Drawing.Image]::FromStream($fileStream)
        $imageFormat = $bitmap.RawFormat
        
        # Create a new 48x48 image
        $newBitmap = New-Object System.Drawing.Bitmap 48, 48
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($bitmap, 0, 0, 48, 48)
        
        # Cleanup before saving
        $graphics.Dispose()
        $bitmap.Dispose()
        $fileStream.Close()
        $fileStream.Dispose()
        
        # Save directly to destination folder (overwrite original)
        $newBitmap.Save($img.FullName, $imageFormat)
        $newBitmap.Dispose()
        
        Write-Host " Resized: $($img.Name)"
    }
    catch {
        Write-Host " Failed to resize $($img.Name): $($_.Exception.Message)"
    }
}

Write-Host "Done resizing all images to 48x48."
