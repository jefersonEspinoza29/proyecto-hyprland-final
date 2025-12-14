#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalador de dotfiles (Hyprland + Waybar + eww + etc.)"

# =========================
# 0. Comprobar que es Arch
# =========================
if ! command -v pacman >/dev/null 2>&1; then
  echo "Esto no parece Arch Linux (no existe pacman). Abortando."
  exit 1
fi

# =========================
# 1. Instalar yay (AUR helper)
# =========================
if ! command -v yay >/dev/null 2>&1; then
  echo "==> Instalando yay..."
  sudo pacman -S --needed --noconfirm git base-devel

  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  cd "$tmpdir/yay"
  makepkg -si --noconfirm
  cd - >/dev/null
  rm -rf "$tmpdir"
else
  echo "==> yay ya está instalado."
fi

# =========================
# 2. Paquetes principales (pacman)
# =========================
PACMAN_PKGS=(
  # core / entorno
  hyprland
  sddm
  waybar
  kitty
  gsimplecal
  gnome-calendar

  # audio / multimedia
  pipewire
  pipewire-pulse
  wireplumber
  pavucontrol
  playerctl
  jq
  pamixer

  # system tray / red / bt / brillo
  blueman
  network-manager-applet
  brightnessctl

  # screenshot / clipboard / portals
  grim
  slurp
  wl-clipboard
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  polkit-gnome

  # fuentes
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji

  # plymouth (splash de arranque)
  plymouth

  # build de brillo (manpage)
  go-md2man
)

# === Drivers Intel (opcional) ===
INTEL_PKGS=(
  mesa
  vulkan-intel
  intel-media-driver
  intel-ucode
)

# === Drivers NVIDIA propietarios (opcional) ===
NVIDIA_PKGS=(
  nvidia
  nvidia-utils
  nvidia-settings
  egl-wayland
  libva-nvidia-driver
)

echo
read -rp "¿Instalar drivers Intel (GPU integrada)? [s/N]: " INSTALL_INTEL
if [[ "$INSTALL_INTEL" =~ ^[sS]$ ]]; then
  PACMAN_PKGS+=("${INTEL_PKGS[@]}")
fi

echo
read -rp "¿Instalar drivers NVIDIA propietarios? [s/N]: " INSTALL_NVIDIA
if [[ "$INSTALL_NVIDIA" =~ ^[sS]$ ]]; then
  PACMAN_PKGS+=("${NVIDIA_PKGS[@]}")
fi

echo "==> Instalando paquetes de pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# =========================
# 3. Paquetes AUR (yay)
# =========================
AUR_PKGS=(
  eww-wayland
  hyprshot
  layer-shell-qt5
  matugen
  swww
  rofi-wayland
)

echo "==> Instalando paquetes de AUR con yay..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# =========================
# 4. Instalar brillo desde GitLab (control de brillo)
# =========================
echo "==> Instalando brillo (control de brillo) desde GitLab..."

BRILLO_TMPDIR="$(mktemp -d)"
cd "$BRILLO_TMPDIR"

git clone https://gitlab.com/cameronnemo/brillo.git
cd brillo
make
sudo make install install.apparmor install.polkit

cd -
rm -rf "$BRILLO_TMPDIR"

echo "==> brillo instalado y carpeta temporal eliminada."

# =========================
# 5. Copiar configuraciones (~/.config)
# =========================
echo "==> Copiando configuraciones a ~/.config"

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_DIRS=(
  eww
  gsimplecal
  hypr
  kitty
  matugen
  rofi
  waybar
  wlogout
)

mkdir -p "$HOME/.config"

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$DOTS_DIR/$dir" ]; then
    echo "  -> $dir"
    mkdir -p "$HOME/.config/$dir"
    cp -r "$DOTS_DIR/$dir/." "$HOME/.config/$dir/"
  else
    echo "  (saltando $dir, no existe en el repo)"
  fi
done

# =========================
# 6. Opcional: habilitar SDDM
# =========================
echo
read -rp "¿Habilitar SDDM y arrancar en modo gráfico (graphical.target)? [s/N]: " ENABLE_SDDM
if [[ "$ENABLE_SDDM" =~ ^[sS]$ ]]; then
  echo "==> Habilitando SDDM y graphical.target..."
  sudo systemctl enable sddm.service
  sudo systemctl set-default graphical.target
fi

# =========================
# 7. Opcional: integrar Plymouth de forma SEGURA
# =========================
echo
read -rp "¿Integrar Plymouth (seguro, sin romper mkinitcpio)? [s/N]: " ENABLE_PLYMOUTH

if [[ "$ENABLE_PLYMOUTH" =~ ^[sS]$ ]]; then
  echo "==> Comprobando mkinitcpio.conf..."

  if ! grep -q "^HOOKS=" /etc/mkinitcpio.conf; then
    echo "❌ ERROR: No se encontró HOOKS en /etc/mkinitcpio.conf"
    echo "Abortando para evitar daños."
    exit 1
  fi

  if grep -q "plymouth" /etc/mkinitcpio.conf; then
    echo "==> Plymouth ya está presente en HOOKS. No se modifica nada."
  else
    echo "==> Creando backup de mkinitcpio.conf..."
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak.$(date +%F_%H-%M-%S)

    echo "==> Insertando 'plymouth' después de 'udev' (método seguro)..."
    sudo sed -i -E \
      's/^(HOOKS=\([^)]*)udev/\1udev plymouth/' \
      /etc/mkinitcpio.conf

    echo "==> Verificando resultado:"
    grep "^HOOKS=" /etc/mkinitcpio.conf

    echo "==> Regenerando initramfs..."
    sudo mkinitcpio -P
  fi

  echo
  echo "==> Verificando systemd-boot..."
  if [[ -d /boot/loader/entries ]]; then
    echo "✔ systemd-boot detectado"

    echo
    echo "IMPORTANTE (NO AUTOMÁTICO PARA EVITAR ERRORES):"
    echo "Edita tu entry principal en /boot/loader/entries/*.conf"
    echo "y agrega SOLO al final de 'options':"
    echo
    echo "    quiet splash"
    echo
    echo "Ejemplo CORRECTO:"
    echo "options root=UUID=xxxx rw quiet splash"
  else
    echo "⚠ No se detectó systemd-boot."
    echo "Si usas GRUB, añade 'quiet splash' en GRUB_CMDLINE_LINUX_DEFAULT"
    echo "y ejecuta: sudo grub-mkconfig -o /boot/grub/grub.cfg"
  fi
else
  echo "==> Plymouth omitido por el usuario."
fi


echo
echo "==> Todo listo 🎉"
echo "   • Revisa ~/.config para ver las configs copiadas."
echo "   • Revisa /boot/loader/entries si quieres terminar de integrar Plymouth (quiet splash)."
echo "   • Inicia sesión en Hyprland para disfrutar el rice."
