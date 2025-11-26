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
# 7. Opcional: integrar Plymouth en mkinitcpio
# =========================
echo
if grep -q "plymouth" /etc/mkinitcpio.conf; then
  echo "==> El hook 'plymouth' ya está presente en /etc/mkinitcpio.conf. Saltando este paso."
else
  read -rp "¿Añadir hook 'plymouth' a /etc/mkinitcpio.conf y regenerar initramfs? [s/N]: " ENABLE_PLYMOUTH
  if [[ "$ENABLE_PLYMOUTH" =~ ^[sS]$ ]]; then
    echo "==> Añadiendo 'plymouth' a HOOKS en /etc/mkinitcpio.conf..."
    # Inserta 'plymouth' después de 'udev' si se encuentra ese patrón
    sudo sed -i 's/^HOOKS=(base udev /HOOKS=(base udev plymouth /' /etc/mkinitcpio.conf || true

    echo "==> Regenerando initramfs (mkinitcpio -P)..."
    sudo mkinitcpio -P

    echo
    echo "IMPORTANTE:"
    echo "  - Aún debes editar tus entradas de systemd-boot en /boot/loader/entries/"
    echo "  - Añade 'quiet splash' al final de la línea 'options' de tu entrada principal."
    echo "  - Asegúrate de tener 'initrd /intel-ucode.img' antes de 'initrd /initramfs-linux.img'."
  else
    echo "==> No se ha tocado /etc/mkinitcpio.conf. Puedes configurar Plymouth a mano más tarde."
  fi
fi

echo
echo "==> Todo listo 🎉"
echo "   • Revisa ~/.config para ver las configs copiadas."
echo "   • Revisa /boot/loader/entries si quieres terminar de integrar Plymouth (quiet splash)."
echo "   • Inicia sesión en Hyprland para disfrutar el rice."
