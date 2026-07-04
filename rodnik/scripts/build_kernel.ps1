# build_kernel.ps1 - Сборка ядер ОС Родник из Windows
param(
    [switch]$All,
    [ValidateSet("asus-nuc14", "matebook-d16", "vivobook-slate13", "depo-storm3400")]
    [string]$Device,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$RodnikDir = "C:\Projects\linux\rodnik"
$OutputDir = "$RodnikDir\output"
$ConfigsDir = "$RodnikDir\configs"
$Version = "6.8"
$BuildDate = Get-Date -Format "yyyyMMdd"
$Arch = "x86_64"

function Write-Color($color, $msg) {
    Write-Host $msg -ForegroundColor $color
}

if ($Help) {
    Write-Color Cyan "Сборка ядер ОС Родник $Version"
    Write-Host "  .\build_kernel.ps1 -All"
    Write-Host "  .\build_kernel.ps1 -Device asus-nuc14"
    exit 0
}

if (-not $All -and -not $Device) {
    Write-Color Red "Укажите -All или -Device"
    exit 1
}

$devices = if ($All) { @("asus-nuc14", "matebook-d16", "vivobook-slate13", "depo-storm3400") } else { @($Device) }

foreach ($dev in $devices) {
    $kernelName = "rodnik-${Version}-${dev}-${BuildDate}-${Arch}.bzImage"
    $deviceDir = "$OutputDir\$dev"
    
    Write-Color Cyan "=== $dev ==="
    Write-Host "  Файл: $kernelName"
    
    New-Item -ItemType Directory -Force -Path $deviceDir | Out-Null
    
    $cmd = @"
cd /mnt/c/Projects/linux
cp rodnik/configs/rodnik-${dev}.config .config
make olddefconfig
make -j`$(nproc) bzImage 2>&1 | tee rodnik/output/${dev}/build.log
if [ -f arch/x86/boot/bzImage ]; then
    mkdir -p rodnik/output/${dev}
    cp arch/x86/boot/bzImage rodnik/output/${dev}/${kernelName}
    cp .config rodnik/output/${dev}/config
    cp System.map rodnik/output/${dev}/System.map 2>/dev/null
    echo "SUCCESS:`$(stat -c%s arch/x86/boot/bzImage)"
else
    echo "FAILED"
    exit 1
fi
"@
    
    $result = wsl bash -c $cmd 2>&1
    
    if ($result -match "SUCCESS:(\d+)") {
        $sizeMB = [math]::Round([int]$Matches[1] / 1MB, 2)
        $color = if ($sizeMB -gt 15) { "Yellow" } else { "Green" }
        Write-Color $color "  Готово: $sizeMB МБ"
        
        # Создаем info.txt
        @"
Устройство: $dev
Версия ядра: $Version
Дата сборки: $BuildDate
Архитектура: $Arch
Размер: $sizeMB МБ
Файл: $kernelName
"@ | Out-File -FilePath "$deviceDir\info.txt" -Encoding UTF8
        
    } else {
        Write-Color Red "  Ошибка! Лог: rodnik/output/$dev/build.log"
    }
}

Write-Color Cyan "=== Готово ==="
Get-ChildItem $OutputDir -Recurse -Filter "*.bzImage" | ForEach-Object {
    $s = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  $($_.Directory.Parent.Name)\$($_.Directory.Name)\$($_.Name): $s МБ"
}