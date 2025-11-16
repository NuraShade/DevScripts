# Change-Icon-Color.ps1
# Usage: & "path/of/script" -FolderPath "destination/folder/path" -Color "White"
# This script changes the color of icons to specified color while preserving transparency

param(
    [string]$FolderPath = ".",
    [string]$Color = "White"
)

# Load .NET assembly for image processing
Add-Type -AssemblyName System.Drawing

# Check if folder exists
if (-not (Test-Path $FolderPath)) {
    Write-Host " Folder not found: $FolderPath"
    exit
}

# Parse color
try {
    $targetColor = [System.Drawing.Color]::FromName($Color)
    if ($targetColor.A -eq 0 -and $Color -ne "Transparent") {
        Write-Host " Invalid color name: $Color"
        exit
    }
}
catch {
    Write-Host " Invalid color: $Color"
    exit
}

# Get all supported image files
$images = Get-ChildItem -Path $FolderPath -Include *.png, *.bmp, *.gif -Recurse

foreach ($img in $images) {
    try {
        # Load image into memory stream to avoid file lock
        $fileStream = [System.IO.File]::OpenRead($img.FullName)
        $bitmap = New-Object System.Drawing.Bitmap $fileStream
        $imageFormat = $bitmap.RawFormat
        $fileStream.Close()
        $fileStream.Dispose()
        
        # Create a new bitmap with same dimensions
        $newBitmap = New-Object System.Drawing.Bitmap $bitmap.Width, $bitmap.Height
        
        # Process each pixel
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            for ($y = 0; $y -lt $bitmap.Height; $y++) {
                $pixel = $bitmap.GetPixel($x, $y)
                
                # If pixel is not transparent, change its color while preserving alpha
                if ($pixel.A -gt 0) {
                    $newPixel = [System.Drawing.Color]::FromArgb($pixel.A, $targetColor.R, $targetColor.G, $targetColor.B)
                    $newBitmap.SetPixel($x, $y, $newPixel)
                }
                else {
                    # Keep transparent pixels transparent
                    $newBitmap.SetPixel($x, $y, $pixel)
                }
            }
        }
        
        # Cleanup and save
        $bitmap.Dispose()
        $newBitmap.Save($img.FullName, $imageFormat)
        $newBitmap.Dispose()
        
        Write-Host " Changed color: $($img.Name)"
    }
    catch {
        Write-Host " Failed to process $($img.Name): $($_.Exception.Message)"
    }
}

Write-Host "Done changing icon colors to $Color."
