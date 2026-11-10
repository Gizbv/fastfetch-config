#!/usr/bin/env bash

# ============================================================
# FASTFETCH — ПОЛУЧЕНИЕ РЕЖИМА ДИСПЛЕЯ ИЗ DRM
# ============================================================
#
# Использование:
#   get-drm-mode.sh <port> <fallback_mode>
#
# Порт передаётся из config.jsonc через переменную окружения
# (например: MONITOR_1_PORT=DP-1).
#
# Скрипт получает текущий режим из /sys/class/drm/card0-<port>/modes
# и выводит его. Если файл не найден или режим пустой,
# возвращает fallback-значение.
#
# Пример из config.jsonc:
#   "text": "get-drm-mode.sh \"$MONITOR_1_PORT\" \"$MONITOR_1_FALLBACK_MODE\""
# ============================================================

set -u

PORT="${1:-}"
FALLBACK="${2:-}"

if [ -z "$PORT" ]; then
    echo "$FALLBACK"
    exit 0
fi

if [ -z "$FALLBACK" ]; then
    FALLBACK="1920x1080"
fi

MODE_FILE="/sys/class/drm/card0-$PORT/modes"

if [ -f "$MODE_FILE" ]; then
    MODE=$(head -n1 "$MODE_FILE" 2>/dev/null)
    if [ -n "$MODE" ]; then
        echo "$MODE"
        exit 0
    fi
fi

echo "$FALLBACK"
