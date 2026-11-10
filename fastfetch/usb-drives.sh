#!/usr/bin/env bash

# ============================================================
# FASTFETCH — ИНДИКАТОР ПОДКЛЮЧЁННЫХ USB-ДИСКОВ
# ============================================================
#
# Скрипт ищет всех USB-блоков по пути симлинка в /sys/class/block/<dev>
# (который содержит "usb" в путях типа usb4/4-2/...).
# Находит точки монтирования через findmnt.
#
# Выводит одну запись на диск в формате:
#   KEY: VALUE
# где KEY - название диска (выравнивание 17 символов),
# VALUE - результат работы usage.sh для точки монтирования.
#
# Пропускает не-USB устройства (ZRAM, NVMe на системной плате и т.д.),
# чтобы в разделе «ДИСКИ» не появились лишние строки.
# При отсутствии подключённых USB-дисков выводит пустоту
# (fastfetch не должен падать).
# ============================================================

set -u

USB_DEVICES=()

# Собираем список USB-устройств, проверяя симлинки в /sys/class/block/<dev>
# Путь содержит "usb" для USB-устройств (например: usb4/4-2/...)
for dev_path in /sys/class/block/*; do
    dev="${dev_path##*/}"
    # Пропускаем zram и другие виртуальные устройства
    [[ "$dev" == zram* ]] && continue
    # Получаем симлинк и проверяем, содержит ли он "usb"
    if [ -L "$dev_path" ]; then
        target="$(readlink "$dev_path" 2>/dev/null)"
        if [[ "$target" == *"usb"* ]]; then
            USB_DEVICES+=("$dev")
        fi
    fi
done

# Нет USB-устройств — выходим без ошибок.
if [ "${#USB_DEVICES[@]}" -eq 0 ]; then
    exit 0
fi

# Обрабатываем каждое USB-устройство и его разделы
for USB_DEVICE in "${USB_DEVICES[@]}"; do
    # Проверяем само устройство (например /dev/sdd)
    if [ -e "/dev/$USB_DEVICE" ]; then
        PART="$USB_DEVICE"
        MOUNT="$(findmnt -n -o TARGET "/dev/$PART" 2>/dev/null)"
        
        if [ -n "$MOUNT" ] && [ -d "$MOUNT" ]; then
            LABEL="$(lsblk -no LABEL "/dev/$PART" 2>/dev/null)"
            FSTYPE="$(lsblk -no FSTYPE "/dev/$PART" 2>/dev/null)"
            
            if [ -z "$LABEL" ]; then
                LABEL="$(basename "$PART")"
            fi
            if [ -z "$FSTYPE" ]; then
                FSTYPE="?"
            fi
            
            SHORT_KEY="${LABEL:-$(basename "$MOUNT")}"
            "$HOME/.config/fastfetch/usage.sh" "$MOUNT"
        fi
    fi
    
    # Проверяем разделы устройства (например /dev/sdd1, /dev/sdd2, ...)
    if [ -d "/sys/class/block/$USB_DEVICE" ]; then
        for part_path in /sys/class/block/$USB_DEVICE/*/; do
            [ -d "$part_path" ] || continue
            PART="${part_path##*/}"
            
            # Пропускаем пустые имена и служебные директории (holders, slaves, subsystem, trace, power)
            [ -n "$PART" ] || continue
            [[ "$PART" == "holders" || "$PART" == "slaves" || "$PART" == "subsystem" || "$PART" == "trace" || "$PART" == "power" ]] && continue
            
            # Пропускаем поддиректории, которые не являются разделами
            [ -e "/sys/class/block/$USB_DEVICE/$PART/uevent" ] || continue
            
            MOUNT="$(findmnt -n -o TARGET "/dev/$PART" 2>/dev/null)"
            
            # Пропускаем, если точка монтирования не найдена или это /dev (корневая файловая система)
            [ -n "$MOUNT" ] || continue
            [ "$MOUNT" != "/dev" ] || continue
            [ -d "$MOUNT" ] || continue
            
            LABEL="$(lsblk -no LABEL "/dev/$PART" 2>/dev/null)"
            FSTYPE="$(lsblk -no FSTYPE "/dev/$PART" 2>/dev/null)"
            
            if [ -z "$LABEL" ]; then
                LABEL="$(basename "$PART")"
            fi
            if [ -z "$FSTYPE" ]; then
                FSTYPE="?"
            fi
            
            SHORT_KEY="${LABEL:-$(basename "$MOUNT")}"
            # Выводим результат usage.sh
            "$HOME/.config/fastfetch/usage.sh" "$MOUNT"
        done
    fi
done
