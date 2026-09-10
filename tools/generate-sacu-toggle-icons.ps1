param(
    [Parameter(Mandatory = $true)]
    [string]$SourceArchive,

    [Parameter(Mandatory = $true)]
    [string]$Texconv
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDirectory = Join-Path $repoRoot 'textures\ui\common\game\orders'
$workDirectory = Join-Path $env:TEMP ('faf-sacu-toggle-icons-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $workDirectory, $outputDirectory | Out-Null

$states = @('up', 'up_sel', 'over', 'over_sel', 'dis', 'dis_sel')
$archiveFiles = @(
    'textures/ui/common/game/seraphim-enhancements/anrf_btn_up.dds',
    'textures/ui/common/game/seraphim-enhancements/nrf_btn_up.dds',
    'textures/ui/common/game/orders/shield-personal_btn_up.dds'
)
foreach ($state in $states) {
    $archiveFiles += "textures/ui/common/game/orders/radar_btn_$state.dds"
}

& tar -xf $SourceArchive -C $workDirectory $archiveFiles
if ($LASTEXITCODE -ne 0) {
    throw "Unable to extract icon sources from $SourceArchive"
}

$sourceFiles = @(
    (Join-Path $workDirectory 'textures\ui\common\game\seraphim-enhancements\anrf_btn_up.dds'),
    (Join-Path $workDirectory 'textures\ui\common\game\seraphim-enhancements\nrf_btn_up.dds'),
    (Join-Path $workDirectory 'textures\ui\common\game\orders\shield-personal_btn_up.dds')
)
foreach ($state in $states) {
    $sourceFiles += Join-Path $workDirectory "textures\ui\common\game\orders\radar_btn_$state.dds"
}

foreach ($source in $sourceFiles) {
    & $Texconv -ft png -y -o $workDirectory $source | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to decode $source"
    }
}

function Get-StatePalette([string]$state) {
    switch ($state) {
        'up'       { return @{ Dark = [Drawing.Color]::FromArgb(255, 73, 126, 61); Bright = [Drawing.Color]::FromArgb(255, 151, 205, 133) } }
        'up_sel'   { return @{ Dark = [Drawing.Color]::FromArgb(255, 73, 126, 61); Bright = [Drawing.Color]::FromArgb(255, 151, 205, 133) } }
        'over'     { return @{ Dark = [Drawing.Color]::FromArgb(255, 93, 146, 78); Bright = [Drawing.Color]::FromArgb(255, 180, 226, 163) } }
        'over_sel' { return @{ Dark = [Drawing.Color]::FromArgb(255, 93, 146, 78); Bright = [Drawing.Color]::FromArgb(255, 180, 226, 163) } }
        'dis'      { return @{ Dark = [Drawing.Color]::FromArgb(255, 48, 55, 48); Bright = [Drawing.Color]::FromArgb(255, 91, 105, 91) } }
        'dis_sel'  { return @{ Dark = [Drawing.Color]::FromArgb(255, 55, 62, 55); Bright = [Drawing.Color]::FromArgb(255, 104, 117, 104) } }
    }
}

function Get-StateBackground([string]$state) {
    switch ($state) {
        'up'       { return @{ Edge = [Drawing.Color]::FromArgb(255, 1, 7, 4); Center = [Drawing.Color]::FromArgb(255, 16, 30, 20) } }
        'up_sel'   { return @{ Edge = [Drawing.Color]::FromArgb(255, 3, 8, 8); Center = [Drawing.Color]::FromArgb(255, 22, 32, 29) } }
        'over'     { return @{ Edge = [Drawing.Color]::FromArgb(255, 17, 31, 18); Center = [Drawing.Color]::FromArgb(255, 75, 105, 64) } }
        'over_sel' { return @{ Edge = [Drawing.Color]::FromArgb(255, 17, 31, 18); Center = [Drawing.Color]::FromArgb(255, 75, 105, 64) } }
        'dis'      { return @{ Edge = [Drawing.Color]::FromArgb(255, 5, 13, 18); Center = [Drawing.Color]::FromArgb(255, 24, 42, 53) } }
        'dis_sel'  { return @{ Edge = [Drawing.Color]::FromArgb(255, 6, 15, 20); Center = [Drawing.Color]::FromArgb(255, 28, 48, 59) } }
    }
}

function Reset-RadarInterior(
    [Drawing.Graphics]$graphics,
    [string]$state,
    [bool]$flat = $false
) {
    $colors = Get-StateBackground $state
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddEllipse(8, 8, 32, 32)
    if ($flat) {
        # The shield/tank glyph has open space below it; a radial highlight in
        # that space looks like an unintended glow.  Keep this icon's interior
        # uniformly dark while preserving the stock outer button rim.
        $brush = [Drawing.SolidBrush]::new($colors.Edge)
        $graphics.FillPath($brush, $path)
        $brush.Dispose()
    } else {
        $brush = [Drawing.Drawing2D.PathGradientBrush]::new($path)
        $brush.CenterColor = $colors.Center
        $brush.SurroundColors = [Drawing.Color[]]@($colors.Edge)
        $brush.CenterPoint = [Drawing.PointF]::new(24, 27)
        $graphics.FillPath($brush, $path)
        $brush.Dispose()
    }
    $path.Dispose()
}

function New-EnhancementDottedRingMask([Drawing.Bitmap]$source) {
    if ($source.Width -ne 64 -or $source.Height -ne 64) {
        throw "Expected a 64x64 Seraphim enhancement icon, got $($source.Width)x$($source.Height)"
    }

    $cropSize = 44
    $sourceOffset = 10
    $center = 21.5
    $active = [bool[]]::new($cropSize * $cropSize)
    $visited = [bool[]]::new($cropSize * $cropSize)
    $ringMask = [bool[]]::new($cropSize * $cropSize)

    # Build connectivity from visible source pixels.  This separates the
    # eight outer dashes from the four inner arcs and the central cross.
    for ($y = 0; $y -lt $cropSize; $y++) {
        for ($x = 0; $x -lt $cropSize; $x++) {
            $pixel = $source.GetPixel($x + $sourceOffset, $y + $sourceOffset)
            $value = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
            $distance = [Math]::Sqrt((($x - $center) * ($x - $center)) + (($y - $center) * ($y - $center)))
            if ($value -ge 10 -and $distance -le 22.5) {
                $active[($y * $cropSize) + $x] = $true
            }
        }
    }

    $selectedComponents = 0
    for ($startY = 0; $startY -lt $cropSize; $startY++) {
        for ($startX = 0; $startX -lt $cropSize; $startX++) {
            $startIndex = ($startY * $cropSize) + $startX
            if (-not $active[$startIndex] -or $visited[$startIndex]) {
                continue
            }

            $queue = [Collections.Generic.Queue[int]]::new()
            $component = [Collections.Generic.List[int]]::new()
            $queue.Enqueue($startIndex)
            $visited[$startIndex] = $true
            $sumRadius = 0.0
            $maxRadius = 0.0

            while ($queue.Count -gt 0) {
                $index = $queue.Dequeue()
                $x = $index % $cropSize
                $y = [int][Math]::Floor($index / $cropSize)
                $distance = [Math]::Sqrt((($x - $center) * ($x - $center)) + (($y - $center) * ($y - $center)))
                $component.Add($index)
                $sumRadius += $distance
                $maxRadius = [Math]::Max($maxRadius, $distance)

                for ($offsetY = -1; $offsetY -le 1; $offsetY++) {
                    for ($offsetX = -1; $offsetX -le 1; $offsetX++) {
                        if ($offsetX -eq 0 -and $offsetY -eq 0) {
                            continue
                        }
                        $nextX = $x + $offsetX
                        $nextY = $y + $offsetY
                        if ($nextX -lt 0 -or $nextX -ge $cropSize -or $nextY -lt 0 -or $nextY -ge $cropSize) {
                            continue
                        }
                        $nextIndex = ($nextY * $cropSize) + $nextX
                        if ($active[$nextIndex] -and -not $visited[$nextIndex]) {
                            $visited[$nextIndex] = $true
                            $queue.Enqueue($nextIndex)
                        }
                    }
                }
            }

            $meanRadius = $sumRadius / $component.Count
            if ($meanRadius -ge 15.0 -and $maxRadius -le 22.5) {
                foreach ($index in $component) {
                    $ringMask[$index] = $true
                }
                $selectedComponents++
            }
        }
    }

    if ($selectedComponents -ne 8) {
        throw "Expected 8 dotted-ring components, found $selectedComponents"
    }
    return ,$ringMask
}

function Add-RecoloredEnhancementCircle(
    [Drawing.Graphics]$graphics,
    [Drawing.Bitmap]$source,
    [string]$state,
    [int]$targetSize,
    [bool]$ringOnly = $false,
    [bool[]]$ringMask = $null
) {
    if ($source.Width -ne 64 -or $source.Height -ne 64) {
        throw "Expected a 64x64 Seraphim enhancement icon, got $($source.Width)x$($source.Height)"
    }

    # The source enhancement is 64x64.  Its circular glyph is centered at
    # 31.5/31.5 and occupies x/y 13..51.  Cut a centered 44x44 disc around it;
    # the square frame lies outside this region.
    $cropSize = 44
    $sourceOffset = 10
    $circle = [Drawing.Bitmap]::new($cropSize, $cropSize)
    $center = 21.5
    $isDisabled = $state -eq 'dis' -or $state -eq 'dis_sel'
    $brightness = if ($state -eq 'over' -or $state -eq 'over_sel') { 1.15 } else { 1.0 }

    for ($y = 0; $y -lt $cropSize; $y++) {
        for ($x = 0; $x -lt $cropSize; $x++) {
            $dx = $x - $center
            $dy = $y - $center
            $distance = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
            if ($distance -gt 22.5) {
                continue
            }
            if ($ringOnly) {
                if ($null -eq $ringMask -or $ringMask.Length -ne ($cropSize * $cropSize)) {
                    throw 'A valid dotted-ring component mask is required'
                }
                if (-not $ringMask[($y * $cropSize) + $x]) {
                    continue
                }
            }

            $pixel = $source.GetPixel($x + $sourceOffset, $y + $sourceOffset)
            $edgeAlpha = if ($distance -le 21.75) { 1.0 } else { (22.5 - $distance) / 0.75 }
            $alpha = [int][Math]::Round($pixel.A * $edgeAlpha)

            if ($isDisabled) {
                $level = (($pixel.R * 0.62) + ($pixel.G * 0.38)) / 255.0
                $r = [int][Math]::Round(91 * $level)
                $g = [int][Math]::Round(105 * $level)
                $b = [int][Math]::Round(112 * $level)
            } else {
                # Linear yellow-to-green hue conversion.  Black stays black,
                # and every bright/dark source detail keeps its original level.
                $r = [int][Math]::Round((($pixel.R * 0.45) + ($pixel.G * 0.15)) * $brightness)
                $g = [int][Math]::Round((($pixel.R * 0.30) + ($pixel.G * 0.69)) * $brightness)
                $b = [int][Math]::Round((($pixel.R * 0.25) + ($pixel.G * 0.35)) * $brightness)
            }

            $r = [Math]::Max(0, [Math]::Min(255, $r))
            $g = [Math]::Max(0, [Math]::Min(255, $g))
            $b = [Math]::Max(0, [Math]::Min(255, $b))
            $circle.SetPixel($x, $y, [Drawing.Color]::FromArgb($alpha, $r, $g, $b))
        }
    }

    $targetX = [int][Math]::Round((48 - $targetSize) / 2)
    $targetY = [int][Math]::Round((48 - $targetSize) / 2)
    $graphics.DrawImage(
        $circle,
        [Drawing.Rectangle]::new($targetX, $targetY, $targetSize, $targetSize),
        [Drawing.Rectangle]::new(0, 0, $cropSize, $cropSize),
        [Drawing.GraphicsUnit]::Pixel)
    $circle.Dispose()
}

function New-ShieldPersonalMask([Drawing.Bitmap]$source) {
    $mask = [Drawing.Bitmap]::new($source.Width, $source.Height)
    for ($y = 9; $y -le 36; $y++) {
        for ($x = 9; $x -le 39; $x++) {
            $pixel = $source.GetPixel($x, $y)
            $value = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
            # Keep the stock tank and dome, but reject their diffuse background.
            $alpha = [Math]::Max(0, [Math]::Min(255, [int](($value - 40) * 7.5)))
            # Shorten the bright rear of the tank without touching the shield
            # dome above it.  Two source columns become roughly 1.5 pixels in
            # the final 48x48 order icon.
            if ($y -ge 25 -and $y -le 30) {
                if ($x -le 10) {
                    $alpha = 0
                } elseif ($x -eq 11) {
                    $alpha = [int][Math]::Round($alpha * 0.35)
                }
            }
            if ($alpha -gt 0) {
                $intensity = [Math]::Max(40, [Math]::Min(230, $value))
                $mask.SetPixel($x, $y, [Drawing.Color]::FromArgb($alpha, $intensity, $intensity, $intensity))
            }
        }
    }

    # The stock button also contributes several disconnected pieces of its
    # circular frame.  Keep only the largest connected component: the tank and
    # its shield dome.  This removes those frame specks without trimming the
    # actual symbol.
    $width = $mask.Width
    $height = $mask.Height
    $visited = [bool[]]::new($width * $height)
    $largestComponent = [Collections.Generic.List[int]]::new()
    for ($startY = 0; $startY -lt $height; $startY++) {
        for ($startX = 0; $startX -lt $width; $startX++) {
            $startIndex = ($startY * $width) + $startX
            if ($visited[$startIndex] -or $mask.GetPixel($startX, $startY).A -eq 0) {
                continue
            }

            $component = [Collections.Generic.List[int]]::new()
            $queue = [Collections.Generic.Queue[int]]::new()
            $queue.Enqueue($startIndex)
            $visited[$startIndex] = $true
            while ($queue.Count -gt 0) {
                $index = $queue.Dequeue()
                $component.Add($index)
                $x = $index % $width
                $y = [int][Math]::Floor($index / $width)
                for ($offsetY = -1; $offsetY -le 1; $offsetY++) {
                    for ($offsetX = -1; $offsetX -le 1; $offsetX++) {
                        if ($offsetX -eq 0 -and $offsetY -eq 0) {
                            continue
                        }
                        $nextX = $x + $offsetX
                        $nextY = $y + $offsetY
                        if ($nextX -lt 0 -or $nextX -ge $width -or $nextY -lt 0 -or $nextY -ge $height) {
                            continue
                        }
                        $nextIndex = ($nextY * $width) + $nextX
                        if (-not $visited[$nextIndex] -and $mask.GetPixel($nextX, $nextY).A -gt 0) {
                            $visited[$nextIndex] = $true
                            $queue.Enqueue($nextIndex)
                        }
                    }
                }
            }
            if ($component.Count -gt $largestComponent.Count) {
                $largestComponent = $component
            }
        }
    }

    $keep = [bool[]]::new($width * $height)
    foreach ($index in $largestComponent) {
        $keep[$index] = $true
    }
    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $index = ($y * $width) + $x
            if (-not $keep[$index] -and $mask.GetPixel($x, $y).A -gt 0) {
                $mask.SetPixel($x, $y, [Drawing.Color]::Transparent)
            }
        }
    }
    return $mask
}

function Add-ScaledSymbol(
    [Drawing.Bitmap]$destination,
    [Drawing.Bitmap]$mask,
    [hashtable]$palette,
    [int]$targetWidth,
    [int]$targetHeight,
    [bool]$preserveSourceLuminance = $false,
    [int]$offsetX = 0,
    [int]$offsetY = 0
) {
    $left = $mask.Width
    $top = $mask.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $mask.Height; $y++) {
        for ($x = 0; $x -lt $mask.Width; $x++) {
            if ($mask.GetPixel($x, $y).A -gt 0) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        return
    }

    $scaled = [Drawing.Bitmap]::new(48, 48)
    $graphics = [Drawing.Graphics]::FromImage($scaled)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $targetX = [int][Math]::Round((48 - $targetWidth) / 2) + $offsetX
    $targetY = [int][Math]::Round((48 - $targetHeight) / 2) + $offsetY
    $sourceRect = [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
    $targetRect = [Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)
    $graphics.DrawImage($mask, $targetRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()

    for ($y = 0; $y -lt 48; $y++) {
        for ($x = 0; $x -lt 48; $x++) {
            $pixel = $scaled.GetPixel($x, $y)
            if ($pixel.A -eq 0) {
                continue
            }

            $background = $destination.GetPixel($x, $y)
            if ($preserveSourceLuminance) {
                # Hue-recolor the enhancement glyph while preserving the
                # original bright/dark hierarchy instead of flattening every
                # dark gold pixel into the same bright green.
                $strength = [Math]::Max(0.0, [Math]::Min(1.0, (($pixel.R - 4) / 220.0) * ($pixel.A / 255.0)))
                $outR = [int][Math]::Round($background.R + (($palette.Bright.R - $background.R) * $strength))
                $outG = [int][Math]::Round($background.G + (($palette.Bright.G - $background.G) * $strength))
                $outB = [int][Math]::Round($background.B + (($palette.Bright.B - $background.B) * $strength))
            } else {
                $factor = [Math]::Max(0.0, [Math]::Min(1.0, ($pixel.R - 40) / 160.0))
                $r = [int][Math]::Round($palette.Dark.R + (($palette.Bright.R - $palette.Dark.R) * $factor))
                $g = [int][Math]::Round($palette.Dark.G + (($palette.Bright.G - $palette.Dark.G) * $factor))
                $b = [int][Math]::Round($palette.Dark.B + (($palette.Bright.B - $palette.Dark.B) * $factor))
                $alpha = $pixel.A / 255.0
                $outR = [int][Math]::Round(($r * $alpha) + ($background.R * (1.0 - $alpha)))
                $outG = [int][Math]::Round(($g * $alpha) + ($background.G * (1.0 - $alpha)))
                $outB = [int][Math]::Round(($b * $alpha) + ($background.B * (1.0 - $alpha)))
            }
            $destination.SetPixel($x, $y, [Drawing.Color]::FromArgb(255, $outR, $outG, $outB))
        }
    }
    $scaled.Dispose()
}

function Add-SpeedAura([Drawing.Graphics]$graphics, [hashtable]$palette) {
    $rect = [Drawing.Rectangle]::new(9, 15, 32, 18)
    $brush = [Drawing.Drawing2D.LinearGradientBrush]::new($rect, $palette.Bright, $palette.Dark, 90)
    $outline = [Drawing.Pen]::new([Drawing.Color]::FromArgb(220, $palette.Dark), 0.9)
    $outline.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    foreach ($x in @(9, 18, 27)) {
        $points = [Drawing.PointF[]]@(
            [Drawing.PointF]::new($x, 16),
            [Drawing.PointF]::new($x + 5, 16),
            [Drawing.PointF]::new($x + 13, 24),
            [Drawing.PointF]::new($x + 5, 32),
            [Drawing.PointF]::new($x, 32),
            [Drawing.PointF]::new($x + 8, 24)
        )
        $graphics.FillPolygon($brush, $points)
        $graphics.DrawPolygon($outline, $points)
    }
    $outline.Dispose()
    $brush.Dispose()
}

function Add-LotusPetal(
    [Drawing.Graphics]$graphics,
    [Drawing.Brush]$fill,
    [Drawing.Pen]$pen,
    [single[]]$points
) {
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $path.StartFigure()
    $path.AddBezier($points[0], $points[1], $points[2], $points[3], $points[4], $points[5], $points[6], $points[7])
    $path.AddBezier($points[6], $points[7], $points[8], $points[9], $points[10], $points[11], $points[12], $points[13])
    $path.AddBezier($points[12], $points[13], $points[14], $points[15], $points[16], $points[17], $points[0], $points[1])
    $path.CloseFigure()
    $graphics.FillPath($fill, $path)
    $graphics.DrawPath($pen, $path)
    $path.Dispose()
}

function Add-Lotus([Drawing.Graphics]$graphics, [hashtable]$palette) {
    $fill = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 0, 0, 0))
    $pen = [Drawing.Pen]::new($palette.Bright, 1.6)
    $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round

    # Rounded, layered water-lily silhouette: no pointed fan of leaves.
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,33, 20,29, 19,22, 21,18, 22,15, 26,15, 27,18, 29,23, 28,29))
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,34, 19,33, 14,29, 13,25, 12,22, 15,20, 18,22, 22,25, 23,30))
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,34, 29,33, 34,29, 35,25, 36,22, 33,20, 30,22, 26,25, 25,30))
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,36, 18,37, 11,34, 9,30, 8,27, 11,26, 14,27, 19,28, 22,33))
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,36, 30,37, 37,34, 39,30, 40,27, 37,26, 34,27, 29,28, 26,33))
    Add-LotusPetal $graphics $fill $pen ([single[]]@(24,38, 20,36, 19,32, 21,30, 22,28, 26,28, 27,30, 29,33, 28,36))
    $graphics.DrawBezier($pen, 10, 33, 17, 39, 31, 39, 38, 33)

    # Tiny lights floating in the open black field above the lotus.  Use a
    # crisp bright center and a four-pixel dark-green halo so DXT5 keeps them.
    $glowColor = [Drawing.Color]::FromArgb(255, $palette.Dark.R, $palette.Dark.G, $palette.Dark.B)
    $glowBrush = [Drawing.SolidBrush]::new($glowColor)
    $coreBrush = [Drawing.SolidBrush]::new($palette.Bright)
    $fireflies = [Drawing.PointF[]]@(
        [Drawing.PointF]::new(16, 17),
        [Drawing.PointF]::new(19, 13),
        [Drawing.PointF]::new(24, 10),
        [Drawing.PointF]::new(29, 13),
        [Drawing.PointF]::new(32, 17)
    )
    foreach ($point in $fireflies) {
        $graphics.FillRectangle($glowBrush, $point.X - 1, $point.Y, 3, 1)
        $graphics.FillRectangle($glowBrush, $point.X, $point.Y - 1, 1, 3)
        $graphics.FillRectangle($coreBrush, $point.X, $point.Y, 1, 1)
    }
    $coreBrush.Dispose()
    $glowBrush.Dispose()
    $pen.Dispose()
    $fill.Dispose()
}

$nrfSource = [Drawing.Bitmap]::new((Join-Path $workDirectory 'nrf_btn_up.png'))
$anrfSource = [Drawing.Bitmap]::new((Join-Path $workDirectory 'anrf_btn_up.png'))
$shieldSource = [Drawing.Bitmap]::new((Join-Path $workDirectory 'shield-personal_btn_up.png'))
$shieldMask = New-ShieldPersonalMask $shieldSource
$nrfRingMask = New-EnhancementDottedRingMask $nrfSource

$icons = @(
    @{ Name = 'sacu-speed-aura'; Kind = 'speed' },
    @{ Name = 'sacu-entropy-aura'; Kind = 'lotus' },
    @{ Name = 'sacu-shield-aura'; Kind = 'shield' },
    @{ Name = 'sacu-vitality-aura'; Kind = 'enhancement-circle'; Source = $nrfSource; Size = 32 },
    @{ Name = 'sacu-restoration-aura'; Kind = 'enhancement-circle'; Source = $anrfSource; Size = 32 }
)

foreach ($icon in $icons) {
    foreach ($state in $states) {
        $base = [Drawing.Bitmap]::new((Join-Path $workDirectory "radar_btn_$state.png"))
        $bitmap = [Drawing.Bitmap]::new($base)
        $base.Dispose()
        $palette = Get-StatePalette $state

        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        Reset-RadarInterior $graphics $state ($icon.Kind -eq 'shield')

        switch ($icon.Kind) {
            'speed'  { Add-SpeedAura $graphics $palette }
            'lotus'  { Add-Lotus $graphics $palette }
            'shield' {
                # Reuse the exact dotted ring from the Seraphim vitality icon.
                # Both it and the tank rectangle are centered at (24, 24).
                Add-RecoloredEnhancementCircle $graphics $nrfSource $state 32 $true $nrfRingMask
                Add-ScaledSymbol $bitmap $shieldMask $palette 22 12 $false 0 0
            }
            'enhancement-circle' { Add-RecoloredEnhancementCircle $graphics $icon.Source $state $icon.Size }
        }
        $graphics.Dispose()

        $pngPath = Join-Path $workDirectory ($icon.Name + "_btn_$state.png")
        $bitmap.Save($pngPath, [Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()

        # System.Drawing saves an sRGB-tagged PNG. FA's legacy DXT5 order icons
        # are sampled as ordinary color data, so a second gamma conversion here
        # would turn the stock green palette almost black in game.
        & $Texconv --ignore-srgb -f DXT5 -m 1 -y -o $outputDirectory $pngPath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to encode $pngPath"
        }
    }
}

$nrfSource.Dispose()
$anrfSource.Dispose()
$shieldSource.Dispose()
$shieldMask.Dispose()

Get-ChildItem $outputDirectory -Filter 'sacu-*-aura_btn_*.DDS' | ForEach-Object {
    $target = Join-Path $_.DirectoryName $_.Name.ToLowerInvariant()
    if ($_.FullName -cne $target) {
        Move-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}

Write-Output "Generated SACU toggle icons in $outputDirectory"
