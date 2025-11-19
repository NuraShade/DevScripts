# usage .\Remove-BlackBackground.ps1 "D:\Images"
param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# Load System.Drawing assembly
Add-Type -AssemblyName System.Drawing

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

        # Create new bitmap with transparency support
        $newImg = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
        
        # Threshold for "black" (adjust if needed - 0-30 is pretty dark)
        $threshold = 30
        
        # Process each pixel
        for ($y = 0; $y -lt $img.Height; $y++) {
            for ($x = 0; $x -lt $img.Width; $x++) {
                $pixel = $img.GetPixel($x, $y)
                
                # Check if pixel is black (or very dark)
                if ($pixel.R -le $threshold -and $pixel.G -le $threshold -and $pixel.B -le $threshold) {
                    # Make it transparent
                    $newImg.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                } else {
                    # Keep original pixel
                    $newImg.SetPixel($x, $y, $pixel)
                }
            }
        }

        $img.Dispose()

        # Save as PNG to preserve transparency
        $outputPath = $file.FullName
        if ($file.Extension -ne ".png") {
            $outputPath = $file.FullName -replace $file.Extension, ".png"
            Write-Host "Converting to PNG: $outputPath"
        }

        $tempFile = "$outputPath.tmp"
        $newImg.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Png)
        $newImg.Dispose()
        
        Move-Item -Path $tempFile -Destination $outputPath -Force

        Write-Host "Black background removed from $($file.Name)"
    }
}

Write-Host "Done!"
