# usage .\Remove-Watermark.ps1 "D:\Images"
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

        # Dimensions
        $w = $img.Width
        $h = $img.Height

        # Watermark area - bottom right corner (adjust size as needed)
        $wmWidth = [int]($w * 0.08)  # 8% of width
        $wmHeight = [int]($h * 0.08)  # 8% of height
        if ($wmWidth -lt 40) { $wmWidth = 40 }
        if ($wmHeight -lt 40) { $wmHeight = 40 }
        if ($wmWidth -gt 100) { $wmWidth = 100 }
        if ($wmHeight -gt 100) { $wmHeight = 100 }

        $startX = $w - $wmWidth
        $startY = $h - $wmHeight

        # Check if image has transparency by sampling the corners
        $hasTransparency = $false
        $cornerPixel = $img.GetPixel(0, 0)
        if ($cornerPixel.A -lt 255) {
            $hasTransparency = $true
        }

        # For transparent images, make watermark area transparent
        # For opaque images, use background color matching
        if ($hasTransparency) {
            $transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
            for ($y = $startY; $y -lt $h; $y++) {
                for ($x = $startX; $x -lt $w; $x++) {
                    $img.SetPixel($x, $y, $transparent)
                }
            }
        } else {
            # Sample background color from edges
            $bgColor = $img.GetPixel(5, 5)
            for ($y = $startY; $y -lt $h; $y++) {
                for ($x = $startX; $x -lt $w; $x++) {
                    $img.SetPixel($x, $y, $bgColor)
                }
            }
        }

        # Save output (overwrite original)
        $tempFile = "$($file.FullName).tmp"
        $img.Save($tempFile)
        $img.Dispose()
        
        Move-Item -Path $tempFile -Destination $file.FullName -Force

        Write-Host "Watermark removed from $($file.Name)"
    }
}

Write-Host "Done!"
