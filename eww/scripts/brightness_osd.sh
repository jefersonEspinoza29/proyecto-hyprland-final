#!/usr/bin/env bash

CFG="$HOME/.config/eww"
STATE_FILE="$HOME/.cache/eww_brightness_osd.last"

ACTION="$1"

# 1. Cambiar brillo
case "$ACTION" in
  up)
    brillo -q -A 5
    ;;
  down)
    brillo -q -U 5
    ;;
esac

# 2. Obtener brillo actual (0-100, redondeado)
BR_LINE="$(brillo -G 2>/dev/null)"
BR="$(awk '{print int($1 + 0.5)}' <<< "$BR_LINE")"

# 3. Actualizar variable de eww
eww -c "$CFG" update br="$BR"

# 4. Mostrar OSD
eww -c "$CFG" open brightness_osd

# 5. Guardar timestamp de este evento
mkdir -p "$HOME/.cache"
NOW="$(date +%s%3N)"
echo "$NOW" > "$STATE_FILE"

# 6. Temporizador: solo cierra si no hubo nuevas pulsaciones en 2 s
(
  sleep 2
  LAST="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"
  if [ "$LAST" = "$NOW" ]; then
    eww -c "$CFG" close brightness_osd
  fi
) &
