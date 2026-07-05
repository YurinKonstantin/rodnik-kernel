# Ядро ОС «Родник» 6.8

Минимальные ядра Linux 6.8 для устройств ОС «Родник». Всё вкомпилировано (без модулей), размер каждого ядра < 15 МБ.

## Поддерживаемые устройства

| Устройство | Процессор | GPU | Драйвер |
|-----------|-----------|-----|---------|
| ASUS NUC 14 Pro | Core Ultra 5 125H | Meteor Lake | Xe + i915 |
| Huawei MateBook D16 | i5-13420H | Raptor Lake | i915 |
| ASUS Vivobook Slate 13 | N6000 | Jasper Lake | i915 |
| DEPO Storm 3400 | Xeon E-2400 | Нет | — |

## Конфигурация

- **MODULES=n** — всё вкомпилировано
- **NET=y** — сеть для всех устройств (E1000, E1000E)
- **BT=y, BT_INTEL=y** — Bluetooth для всех
- **IWLWIFI=y** — WiFi для клиентских устройств (кроме сервера)
- **DRM_I915=y, DRM_XE=y** — графика Intel
- **BLK_DEV_INITRD=y** — поддержка initramfs
- **SQUASHFS=y, ISO9660_FS=y** — поддержка rootfs и ISO

## Структура проекта

## Быстрый старт

### Требования

- Windows 11 + WSL Ubuntu
- Установленные пакеты в WSL:
  ```bash
  sudo apt-get update
  sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev bc \
    grub-pc-bin grub-efi-amd64-bin xorriso mtools squashfs-tools wget
## Сборка всех ядер
cd /mnt/c/Projects/linux

# 1. Сгенерировать конфиги
bash rodnik/scripts/generate-configs.sh

# 2. Собрать все ядра
bash rodnik/scripts/build-all.sh

Результаты в rodnik/output/{device}/ — по одному bzImage на устройство.

Сборка ISO образов (с rootfs и композитором)
bash
# Сборка rootfs + ISO
bash rodnik/scripts/build_all_iso.sh
Результаты:

text
rodnik/output/asus-nuc14/rodnik-asus-nuc14-YYYYMMDD.iso
rodnik/output/matebook-d16/rodnik-matebook-d16-YYYYMMDD.iso
rodnik/output/vivobook-slate13/rodnik-vivobook-slate13-YYYYMMDD.iso
rodnik/output/depo-storm3400/rodnik-depo-storm3400-YYYYMMDD.iso
Полный цикл (композитор + ядра + ISO)
bash
bash rodnik/scripts/build_full.sh
Проверка работоспособности
1. Проверка ядра + initramfs (минимальный тест)
bash
cd /mnt/c/Projects/linux/rodnik/initramfs

# Создать тестовый initramfs
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > /tmp/test.cpio.gz

# Запустить ядро с initramfs
qemu-system-x86_64 \
    -m 1G \
    -kernel rodnik/output/asus-nuc14/bzImage \
    -initrd /tmp/test.cpio.gz \
    -serial stdio \
    -display none \
    -no-reboot \
    -append "console=ttyS0"
Ожидаемый результат: появится shell ~ #. Значит ядро и initramfs работают.

2. Проверка ISO с rootfs
bash
qemu-system-x86_64 \
    -m 2G \
    -cdrom rodnik/output/asus-nuc14/rodnik-asus-nuc14-*.iso \
    -serial stdio \
    -display none \
    -no-reboot
3. Проверка с графическим интерфейсом (VNC)
bash
qemu-system-x86_64 \
    -m 4G \
    -smp 4 \
    -cdrom rodnik/output/asus-nuc14/rodnik-asus-nuc14-*.iso \
    -vnc :1 \
    -no-reboot
Подключиться к VNC: vncviewer localhost:5901

4. Проверка конкретных компонентов внутри QEMU
В shell внутри виртуальной машины:

bash
# Информация о ядре
uname -r

# Проверка файловых систем
cat /proc/filesystems | grep -E "ext4|squashfs|iso9660"

# Проверка блочных устройств
ls -la /dev/sd* /dev/sr*

# Проверка initramfs
ls -la /bin /sbin

# Проверка rootfs (если используется)
ls -la /opt/rodnik/
ldd /opt/rodnik/Rodnik.Compositor
Расположение собранных файлов
text
rodnik/output/
├── asus-nuc14/
│   ├── bzImage                              — ядро
│   ├── rodnik-6.8-asus-nuc14-YYYYMMDD-x86_64.bzImage  — ядро с версией
│   ├── initramfs.cpio.gz                    — initramfs
│   ├── rodnik-asus-nuc14-YYYYMMDD.iso       — загрузочный ISO
│   ├── config                               — конфиг ядра
│   ├── System.map                           — карта символов
│   ├── build.log                            — лог сборки
│   └── info.txt                             — информация о сборке
├── matebook-d16/
│   └── ...
├── vivobook-slate13/
│   └── ...
└── depo-storm3400/
    └── ...
Запись ISO на USB
bash
sudo dd if=rodnik/output/asus-nuc14/rodnik-asus-nuc14-*.iso of=/dev/sdX bs=4M status=progress
Где /dev/sdX — USB-накопитель.

Лицензия
GPL-2.0
