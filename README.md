# Hyprland Dotfiles (Arch Linux)

Rice de Hyprland para Arch Linux con:

- Hyprland (Wayland compositor)
- SDDM como display manager
- Waybar
- eww (widgets)
- rofi-wayland
- kitty
- gsimplecal / gnome-calendar
- swww, matugen
- blueman, network-manager-applet, brightnessctl
- grim + slurp + wl-clipboard
- Plymouth (splash de arranque) opcional
- brillo (control de brillo desde terminal)

Toda la configuración de usuario vive en `~/.config` para que puedas usarla con cualquier usuario.

---

## Requisitos

- Arch Linux (o derivado rolling) con `pacman`.
- UEFI + **systemd-boot** recomendado (el README asume esto para Plymouth).
- Conexión a internet.
- Cuenta con permisos `sudo`.

---

## Instalación rápida

Durante el install podrás elegir:

Si instalar drivers Intel y/o NVIDIA.

Si habilitar SDDM y arrancar en graphical.target.

Si añadir automáticamente el hook plymouth a mkinitcpio.conf.

El script:

Comprueba que estás en Arch (existe pacman).

Instala yay si no está presente.

Instala paquetes base con pacman:

hyprland sddm waybar kitty gsimplecal gnome-calendar

pipewire pipewire-pulse wireplumber pavucontrol playerctl jq

blueman network-manager-applet brightnessctl

grim slurp wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-gtk polkit-gnome

ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

plymouth

go-md2man

(opcional) mesa vulkan-intel intel-media-driver intel-ucode y/o paquetes NVIDIA

Instala paquetes AUR con yay:

eww-wayland hyprshot layer-shell-qt5 matugen swwww rofi-wayland

Compila e instala brillo desde GitLab:

https://gitlab.com/cameronnemo/brillo.git

Copia las carpetas de configuración desde el repo a ~/.config:

eww, gsimplecal, hypr, kitty, matugen, rofi, waybar, wlogout

(Opcional) habilita SDDM y pone graphical.target como target por defecto.

(Opcional) añade el hook plymouth en /etc/mkinitcpio.conf y ejecuta mkinitcpio -P.

---

1. HOOKS de mkinitcpio.conf

Edita:

sudo nano /etc/mkinitcpio.conf


Deja la línea de HOOKS así (ejemplo típico sin cifrado):

HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)


Regenera el initramfs:

sudo mkinitcpio -P

2. Entradas de systemd-boot

Lista tus entradas:

ls /boot/loader/entries


Edita tu entrada principal, por ejemplo:

sudo nano /boot/loader/entries/2025-11-18_04-31-22_linux.conf


Ejemplo de contenido recomendado:

title   Arch Linux (linux)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=TU-PARTUUID zswap.enabled=0 rw rootfstype=ext4 quiet splash


Puntos clave:

Añadir initrd /intel-ucode.img antes de initrd /initramfs-linux.img (si usas CPU Intel).

Añadir quiet splash al final de la línea options.

Puedes hacer algo similar en tu entrada -fallback:

title   Arch Linux (linux, fallback)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux-fallback.img
options root=PARTUUID=TU-PARTUUID zswap.enabled=0 rw rootfstype=ext4 quiet splash

3. loader.conf

Opcional pero útil:

sudo nano /boot/loader/loader.conf


Ejemplo:

default 2025-11-18_04-31-22_linux.conf
timeout 3
console-mode keep


default → nombre del archivo de tu entrada principal.

timeout → segundos que se muestra el menú de arranque.

4. Elegir tema de Plymouth

Lista temas disponibles:

sudo plymouth-set-default-theme -l


Elegir un tema (por ejemplo spinner):

sudo plymouth-set-default-theme -R spinner


El -R regenera el initramfs automáticamente.

Reinicia y deberías ver el splash de Plymouth antes de SDDM.

Notas multiusuario

El script copia las configuraciones a ~/.config del usuario que ejecuta ./install.

Si creas otro usuario en el sistema, puedes:

Volver a ejecutar ./install con ese usuario, o

Copiar manualmente las carpetas de ~/.config desde un usuario a otro.


## Instalación rápida

```bash
git clone https://github.com/tu-usuario/tu-repo-dotfiles.git
cd tu-repo-dotfiles
chmod +x install
./install


