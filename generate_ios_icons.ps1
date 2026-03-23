# PowerShell script to generate iOS app icons from appstore.png
# This script resizes your appstore.png to all required iOS icon sizes

Add-Type -AssemblyName System.Drawing

$sourceImage = "f:\Flutter\FlutterProjects\magical_community\assets\icons\appstore.png"
$outputDir = "f:\Flutter\FlutterProjects\magical_community\ios\Runner\Assets.xcassets\AppIcon.appiconset"

# Check if source image exists
if (-not (Test-Path $sourceImage)) {
    Write-Error "Source image not found: $sourceImage"
    exit 1
}

Write-Host "Loading source image: $sourceImage"
$bitmap = [System.Drawing.Bitmap]::FromFile($sourceImage)

# iOS App Icon sizes (size x scale = actual pixel size)
$iconSizes = @(
    @{ Name = "Icon-App-20x20@1x.png"; Size = 20 },
    @{ Name = "Icon-App-20x20@2x.png"; Size = 40 },
    @{ Name = "Icon-App-20x20@3x.png"; Size = 60 },
    @{ Name = "Icon-App-29x29@1x.png"; Size = 29 },
    @{ Name = "Icon-App-29x29@2x.png"; Size = 58 },
    @{ Name = "Icon-App-29x29@3x.png"; Size = 87 },
    @{ Name = "Icon-App-40x40@1x.png"; Size = 40 },
    @{ Name = "Icon-App-40x40@2x.png"; Size = 80 },
    @{ Name = "Icon-App-40x40@3x.png"; Size = 120 },
    @{ Name = "Icon-App-60x60@2x.png"; Size = 120 },
    @{ Name = "Icon-App-60x60@3x.png"; Size = 180 },
    @{ Name = "Icon-App-76x76@1x.png"; Size = 76 },
    @{ Name = "Icon-App-76x76@2x.png"; Size = 152 },
    @{ Name = "Icon-App-83.5x83.5@2x.png"; Size = 167 },
    @{ Name = "Icon-App-1024x1024@1x.png"; Size = 1024 }
)

Write-Host "Generating icon sizes..."

foreach ($icon in $iconSizes) {
    $size = $icon.Size
    $filename = $icon.Name
    $outputPath = Join-Path $outputDir $filename
    
    Write-Host "Creating $filename ($size x $size pixels)"
    
    # Create new bitmap with desired size
    $resizedBitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedBitmap)
    
    # Set high quality settings
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    
    # Draw the resized image
    $graphics.DrawImage($bitmap, 0, 0, $size, $size)
    
    # Save the resized image
    $resizedBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Cleanup
    $graphics.Dispose()
    $resizedBitmap.Dispose()
}

# Cleanup
$bitmap.Dispose()

Write-Host "✅ All iOS app icons generated successfully!"
Write-Host "Icons saved to: $outputDir"
