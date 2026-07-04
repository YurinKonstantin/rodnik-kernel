#!/bin/bash
# Сборка всех ядер ОС Родник
set -e

KERNEL="/mnt/c/Projects/linux"
RODNIK="$KERNEL/rodnik"
OUTPUT="$RODNIK/output"
CONFIGS="$RODNIK/configs"

# Версия и дата сборки
VERSION="6.8"
BUILD_DATE=$(date +%Y%m%d)
ARCH="x86_64"

echo "============================================"
echo "  Сборка ядер ОС Родник"
echo "  Версия: $VERSION"
echo "  Дата: $BUILD_DATE"
echo "  Архитектура: $ARCH"
echo "============================================"

cd "$KERNEL"

for config in "$CONFIGS"/rodnik-*.config; do
    # Имя устройства из имени файла
    device=$(basename "$config" .config | sed 's/rodnik-//')
    
    # Папка для устройства
    device_dir="$OUTPUT/$device"
    mkdir -p "$device_dir"
    
    # Имя файла ядра
    kernel_name="rodnik-${VERSION}-${device}-${BUILD_DATE}-${ARCH}.bzImage"
    
    echo ""
    echo "=== $device ==="
    echo "  Файл: $kernel_name"
    
    # Копируем конфиг
    cp "$config" .config
    
    # Обновляем конфиг
    make olddefconfig
    
    # Собираем
    echo "  Сборка..."
    make -j$(nproc) bzImage 2>&1 | tee "$device_dir/build.log"
    
    # Проверяем результат
    if [ -f arch/x86/boot/bzImage ]; then
        cp arch/x86/boot/bzImage "$device_dir/$kernel_name"
        
        # Копируем System.map
        if [ -f System.map ]; then
            cp System.map "$device_dir/System.map"
        fi
        
        # Копируем конфиг
        cp .config "$device_dir/config"
        
        # Размер
        size=$(stat -c%s "$device_dir/$kernel_name")
        size_mb=$(( size / 1048576 ))
        
        echo "  ✓ Готово: ${size_mb} МБ"
        
        # Создаем info.txt
        cat > "$device_dir/info.txt" << INFO
Устройство: $device
Версия ядра: $VERSION
Дата сборки: $BUILD_DATE
Архитектура: $ARCH
Размер: ${size_mb} МБ
Файл: $kernel_name
INFO
        
    else
        echo "  ✗ Ошибка сборки!"
        exit 1
    fi
    
    # Чистим
    make clean 2>/dev/null || rm -rf Documentation/output
done

echo ""
echo "============================================"
echo "  Сборка завершена"
echo "============================================"
echo ""

# Показываем что получилось
for dir in "$OUTPUT"/*/; do
    device=$(basename "$dir")
    kernel=$(ls "$dir"/*.bzImage 2>/dev/null)
    if [ -n "$kernel" ]; then
        size=$(stat -c%s "$kernel")
        size_mb=$(( size / 1048576 ))
        echo "  $device: $(basename "$kernel") (${size_mb} МБ)"
    fi
done
