#!/bin/bash
# Сборка всех ядер ОС Родник
set -e

KERNEL="/mnt/c/Projects/linux"
OUTPUT="$KERNEL/rodnik/output"
CONFIGS="$KERNEL/rodnik/configs"

echo "=== Сборка ядер ОС Родник ==="
mkdir -p "$OUTPUT"
cd "$KERNEL"

for config in "$CONFIGS"/rodnik-*.config; do
    dev=$(basename "$config" .config | sed 's/rodnik-//')
    echo ""
    echo "=== $dev ==="
    
    cp "$config" .config
    make olddefconfig
    make -j$(nproc) bzImage
    
    if [ -f arch/x86/boot/bzImage ]; then
        cp arch/x86/boot/bzImage "$OUTPUT/bzImage-${dev}"
        size=$(stat -c%s arch/x86/boot/bzImage)
        size_mb=$(( size / 1048576 ))
        echo "  Готово: ${size_mb} МБ ($size байт)"
    else
        echo "  ОШИБКА!"
        exit 1
    fi
    
    make clean
done

echo ""
echo "=== Все ядра собраны ==="
ls -lh "$OUTPUT"/bzImage-*
