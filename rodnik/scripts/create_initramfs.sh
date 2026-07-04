#!/bin/bash
# Создание initramfs для ОС Родник
set -e

BUSYBOX_VER="1.36.1"
RODNIK="/mnt/c/Projects/linux/rodnik"
INITRAMFS="$RODNIK/initramfs"
OUTPUT="$RODNIK/output/initramfs.cpio.gz"

echo "=== Создание initramfs ==="

# Busybox
if [ ! -f "$INITRAMFS/bin/busybox" ]; then
    echo "Сборка busybox..."
    TMP=/tmp/busybox-$$
    mkdir -p "$TMP" && cd "$TMP"
    wget -q "https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
    tar xf "busybox-${BUSYBOX_VER}.tar.bz2"
    cd "busybox-${BUSYBOX_VER}"
    make defconfig
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    make -j$(nproc) 2>&1 | tail -1
    mkdir -p "$INITRAMFS/bin"
    cp busybox "$INITRAMFS/bin/"
    cd "$INITRAMFS/bin"
    for a in $(./busybox --list); do ln -sf busybox "$a" 2>/dev/null; done
    rm -rf "$TMP"
    echo "Busybox OK"
fi

# X11
mkdir -p "$INITRAMFS/usr/bin" "$INITRAMFS/usr/lib/x86_64-linux-gnu" "$INITRAMFS/opt/rodnik"
cp /usr/bin/Xorg "$INITRAMFS/usr/bin/" 2>/dev/null || true
cp /usr/bin/xinit "$INITRAMFS/usr/bin/" 2>/dev/null || true

# Композитор
if [ ! -f "$INITRAMFS/opt/rodnik/Rodnik.Compositor" ]; then
    cat > "$INITRAMFS/opt/rodnik/Rodnik.Compositor" << 'EOF'
#!/bin/sh
echo "Rodnik Compositor"
sleep infinity
EOF
    chmod +x "$INITRAMFS/opt/rodnik/Rodnik.Compositor"
fi

# Сборка образа
cd "$INITRAMFS"
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$OUTPUT"
echo "Готово: $(stat -c%s "$OUTPUT") байт"
