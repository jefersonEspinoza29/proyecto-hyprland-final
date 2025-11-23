#!/usr/bin/env bash

CFG="$HOME/.config/eww"
STATE_FILE="$HOME/.cache/eww_volume_osd.last"

ACTION="$1"

# 1. Cambiar volumen
case "$ACTION" in
  up)
    wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
    ;;
  down)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
esac

# 2. Obtener volumen actual (0–100) directamente aqui
VOL_LINE="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
# Ejemplos de salida:
#   Volume: 0.35
#   Volume: 0.35 [MUTED]
VOL="$(awk '{print int($2*100 + 0.5)}' <<< "$VOL_LINE")"

# 3. Actualizar la variable de eww
eww -c "$CFG" update vol="$VOL"

# 4. Mostrar el OSD (si ya esta abierto, no lo recrea)
eww -c "$CFG" open volume_osd

# 5. Guardar timestamp de esta pulsacion
mkdir -p "$HOME/.cache"
NOW="$(date +%s%3N)"   # segundos + milisegundos
echo "$NOW" > "$STATE_FILE"

# 6. Temporizador en segundo plano:
#    solo cierra si NO hubo nuevas pulsaciones en 2s
(
  sleep 2
  LAST="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"
  if [ "$LAST" = "$NOW" ]; then
    eww -c "$CFG" close volume_osd
  fi
) &
