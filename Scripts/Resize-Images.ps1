# Resize-Images.ps1
#Usage & "path/of/script" -FolderPath "destination/folder/path" -OutputFolder "output/fiolder/path"
# This script resizes all images in a folder to 48x48 pixels using .NET

# Get current folder or ask user for path
param(
    [string]$FolderPath = ".",
    [string]$OutputFolder = ""
)

# Load .NET assembly for image processing
Add-Type -AssemblyName System.Drawing

# Check if folder exists
if (-not (Test-Path $FolderPath)) {
    Write-Host " Folder not found: $FolderPath"
    exit
}

# Create output folder if specified
if ($OutputFolder -ne "") {
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }
}

# Get all supported image files
$images = Get-ChildItem -Path $FolderPath -Include *.png, *.jpg, *.jpeg, *.bmp, *.gif -Recurse

foreach ($img in $images) {
    try {
        $bitmap = [System.Drawing.Image]::FromFile($img.FullName)
        
        # Create a new 48x48 image
        $newBitmap = New-Object System.Drawing.Bitmap 48, 48
        $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($bitmap, 0, 0, 48, 48)
        
        # Save output
        $outputPath = if ($OutputFolder -ne "") {
            Join-Path $OutputFolder $img.Name
        } else {
            $img.FullName
        }
        $newBitmap.Save($outputPath, $bitmap.RawFormat)
        
        Write-Host " Resized: $($img.Name)"
        
        # Cleanup
        $graphics.Dispose()
        $newBitmap.Dispose()
        $bitmap.Dispose()
    }
    catch {
        Write-Host " Failed to resize $($img.Name): $($_.Exception.Message)"
    }
}

Write-Host "Done resizing all images to 48x48."
