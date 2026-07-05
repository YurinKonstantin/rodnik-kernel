#!/bin/bash
# Сборка тестового ISO: Alpine Linux + ядро Родник + i3
set -e

ALPINE_VER="3.20.0"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-standard-${ALPINE_VER}-x86_64.iso"
WORK_DIR="/tmp/rodnik-alpine-$$"
OUTPUT_DIR="/mnt/c/Projects/linux/rodnik/output"
DEVICE="${1:-asus-nuc14}"

echo "=== Сборка тестового ISO ==="
echo "  Устройство: $DEVICE"
echo "  База: Alpine $ALPINE_VER"

KERNEL="$OUTPUT_DIR/$DEVICE/bzImage"
if [ ! -f "$KERNEL" ]; then
    echo "ОШИБКА: ядро не найдено: $KERNEL"
    exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "[1/5] Скачивание Alpine..."
wget -q "$ALPINE_URL" -O alpine.iso

echo "[2/5] Распаковка ISO..."
mkdir iso
sudo mount -o loop alpine.iso /mnt
sudo cp -r /mnt/* iso/
sudo cp -r /mnt/.??* iso/ 2>/dev/null || true
sudo umount /mnt

echo "[3/5] Замена ядра..."
sudo cp "$KERNEL" iso/boot/vmlinuz-lts

echo "[4/5] Настройка загрузчика..."
cat > iso/boot/grub/grub.cfg << 'GRUB'
set timeout=3
menuentry "Rodnik + Alpine" {
    linux /boot/vmlinuz-lts quiet
    initrd /boot/initramfs-lts
}
GRUB

echo "[5/5] Сборка ISO..."
ISO_NAME="rodnik-alpine-${DEVICE}-$(date +%Y%m%d).iso"
ISO_PATH="$OUTPUT_DIR/$DEVICE/$ISO_NAME"
mkdir -p "$OUTPUT_DIR/$DEVICE"

sudo grub-mkrescue -o "$ISO_PATH" iso/ 2>&1 | tail -1

cd /
sudo rm -rf "$WORK_DIR"

echo "Готово: $ISO_PATH"
ls -lh "$ISO_PATH"