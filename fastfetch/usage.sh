#!/usr/bin/env bash

# ============================================================
# FASTFETCH — ИНДИКАТОР ЗАПОЛНЕННОСТИ ДИСКА
# ============================================================
#
# Использование:
#   usage.sh /mnt/GAMES
#
# Скрипт получает путь к файловой системе, автоматически
# определяет использованный и общий объём, рассчитывает
# процент заполнения и формирует графическую полоску.
#
# Путь к диску передаётся из config.jsonc.
# Название диска выводит сам FastFetch через параметр "key".
#
# Цвет полоски:
#   0–69%  — зелёный
#   70–89% — жёлтый
#   90%+   — красный
#
# BAR_WIDTH определяет длину полоски.
# ============================================================

set -u

TARGET="${1:-/}"
BAR_WIDTH=16

read -r SIZE USED PERCENT <<< "$(df -hP "$TARGET" | awk 'NR==2 {
    print $2, $3, $5
}')"

PCT="${PERCENT%\%}"

if ! [[ "$PCT" =~ ^[0-9]+$ ]]; then
    exit 1
fi

FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))

FILLED_BAR=""
EMPTY_BAR=""

for ((i=0; i<FILLED; i++)); do
    FILLED_BAR+="▀"
done

for ((i=0; i<EMPTY; i++)); do
    EMPTY_BAR+="▀"
done

if (( PCT >= 90 )); then
    COLOR='\033[31m'
elif (( PCT >= 70 )); then
    COLOR='\033[33m'
else
    COLOR='\033[32m'
fi

EMPTY_COLOR='\033[2;32m'
RESET='\033[0m'

printf '%7s / %-5s  [%b%s%b%b%s%b] %3s\n' \
    "$USED" \
    "$SIZE" \
    "$COLOR" \
    "$FILLED_BAR" \
    "$RESET" \
    "$EMPTY_COLOR" \
    "$EMPTY_BAR" \
    "$RESET" \
    "$PERCENT"
