#!/usr/bin/env bash

# ============================================================
# FASTFETCH — ИНДИКАТОР ИСПОЛЬЗОВАНИЯ ОПЕРАТИВНОЙ ПАМЯТИ
# ============================================================
#
# Скрипт получает данные непосредственно из free,
# рассчитывает процент использования RAM и формирует
# графическую полоску фиксированной длины.
#
# Блок с объёмом памяти имеет фиксированную ширину,
# поэтому положение прогресс-бара не изменяется
# при изменении количества используемой памяти.
#
# Процент рассчитывается как:
#   used / total × 100
#
# Цвет полоски:
#   0–69%  — зелёный
#   70–89% — жёлтый
#   90%+   — красный
#
# BAR_WIDTH определяет длину полоски.
# ============================================================

set -u

BAR_WIDTH=16
PREFIX_WIDTH=26

read -r TOTAL USED <<< "$(free -b | awk '/^Mem:/ {
    print $2, $3
}')"

PCT=$(( USED * 100 / TOTAL ))

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

USED_GIB=$(awk -v v="$USED" 'BEGIN {printf "%.2f", v/1024/1024/1024}')
TOTAL_GIB=$(awk -v v="$TOTAL" 'BEGIN {printf "%.2f", v/1024/1024/1024}')

# Фиксированная ширина блока с объёмом памяти.
# Благодаря этому прогресс-бар всегда начинается
# в одной и той же колонке независимо от значения USED.
printf -v PREFIX "%-*s" "$PREFIX_WIDTH" "$USED_GIB GiB / $TOTAL_GIB GiB"

printf '%s[%b%s%b%b%s%b]%3d%%\n' \
    "$PREFIX" \
    "$COLOR" \
    "$FILLED_BAR" \
    "$RESET" \
    "$EMPTY_COLOR" \
    "$EMPTY_BAR" \
    "$RESET" \
    "$PCT"
