# Instalación limpia en NixOS

Guía para levantar este entorno —  Hyprland + noctalia, tema Catppuccin Mocha —
desde una máquina vacía. La rama `nixos` de este repo contiene tanto los
dotfiles como la declaración del sistema.

> Para el día a día una vez instalado, salta a [Operación diaria](#operación-diaria).
> Para qué hace cada tecla y cómo se toca cada herramienta, sigue valiendo el
> `README.md`.

---

## Qué asume esta guía

- Portátil AMD (Ryzen + iGPU Radeon), arranque **UEFI**.
- Un disco que se va a **formatear entero**. Si necesitas conservar particiones,
  adapta el paso 2 y no copies los comandos a ciegas.
- Un solo usuario: `vgonz`.
- Conexión a internet durante toda la instalación.

Lo que **no** está en este repo y tendrás que traer de tus copias de seguridad:

| Qué | Dónde va |
|---|---|
| Galería de fondos | `~/Pictures/Wallpapers/` |
| Claves SSH / GPG | `~/.ssh/`, `~/.gnupg/` |
| Identidad de git (`user.name`, `user.email`) | `git config --global` |

---

## 1. Arrancar el instalador

Descarga la ISO **minimal** de NixOS (`nixos-minimal-*-x86_64-linux.iso`) desde
<https://nixos.org/download>, grábala en un USB y arranca desde ella.

Ya dentro:

```bash
sudo -i                      # el instalador trabaja como root
loadkeys us
```

Red por cable: no hay nada que hacer. Por wifi:

```bash
systemctl start wpa_supplicant
wpa_cli
# > add_network / set_network 0 ssid "MiRed" / set_network 0 psk "clave"
# > enable_network 0 / quit
ping -c3 nixos.org
```

---

## 2. Particionar e instalar la base

Identifica el disco (`lsblk`). En lo que sigue se asume `/dev/nvme0n1`;
**cámbialo por el tuyo** — estos comandos borran datos.

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1GiB 100%

mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos      /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
```

Genera la configuración de hardware e instala una base mínima:

```bash
nixos-generate-config --root /mnt
nixos-install                 # pide la contraseña de root al terminar
reboot
```

> Esto instala un NixOS pelado a propósito. La configuración real se aplica en
> el paso 4, ya desde el sistema instalado, para que el `hardware-configuration.nix`
> que genera `nixos-generate-config` sea el de esta máquina.

---

## 3. Primer arranque: usuario y red

Entra como `root` con la contraseña que pusiste y crea tu usuario:

```bash
useradd -m -G wheel vgonz
passwd vgonz
```

Conecta a la red si hace falta (`nmtui` no está aún; usa `wpa_cli` como arriba),
y entra como `vgonz`:

```bash
su - vgonz
```

---

## 4. Aplicar esta configuración

```bash
nix-shell -p git --run 'git clone -b nixos https://github.com/goslynn/archbtw-hyprm-dotfiles.git ~/.dotfiles'
~/.dotfiles/install.sh
```

O de una sola vez:

```bash
nix-shell -p curl --run 'curl -fsSL https://raw.githubusercontent.com/goslynn/archbtw-hyprm-dotfiles/nixos/install.sh' | bash
```

El script es **re-ejecutable**: si algo falla a mitad, arréglalo y vuelve a
lanzarlo. Hace, en orden:

| Paso | Qué hace | Cómo comprobarlo |
|---|---|---|
| 1 | Verifica NixOS, red y git | falla con un mensaje claro si no |
| 2 | Clona el repo en `~/.dotfiles` | `git -C ~/.dotfiles log -1` |
| 3 | Copia `/etc/nixos/hardware-configuration.nix` al repo | `git -C ~/.dotfiles status` lo muestra modificado |
| 4 | `nixos-rebuild switch --flake ~/.dotfiles#laptop` | tarda; compila poco, casi todo viene de caché |
| 5 | Restaura la config de noctalia y limpia la capa de estado | `noctalia config validate` |
| 6 | Crea `~/Pictures/Wallpapers` | — |

> **Sobre el paso 3:** el `hardware-configuration.nix` del repo es un
> *placeholder* que no describe ningún disco real. Existe solo para que el flake
> evalúe antes de instalar nada. El script lo sustituye por el de tu máquina —
> commitea ese cambio, pero no esperes que sirva en otro equipo.

Cuando termine: reinicia.

```bash
sudo reboot
```

---

## 5. Después del primer login

Te recibe **noctalia-greeter**. Elige la sesión `Hyprland` y entra.

Quedan dos cosas manuales:

1. **Restaura tus fondos** en `~/Pictures/Wallpapers/` y elige uno desde el
   selector de noctalia.
2. **Sincroniza el aspecto con la pantalla de login:**
   `noctalia` → Settings → Security → Noctalia Greeter → **Sync Now**.

   Esto no es automático, y hay que repetirlo cada vez que cambies de fondo o
   de paleta. El motivo es deliberado: la parte declarativa
   (`nix/system/greeter.nix`) fija solo sesión, usuario, cursor y teclado, y
   **no** declara la paleta — porque las claves de `greeter.toml` ganan sobre lo
   que sincroniza el shell, y declararla dejaría al greeter congelado en un
   tema que noctalia ya no podría cambiar.

También en el primer arranque, noctalia descarga de `api.noctalia.dev` su
template community (`yazi`) y la paleta *Catppuccin Mocha Lavender*. Sin red el
tema arranca degradado hasta la siguiente conexión.

---

## Operación diaria

| Cambio | Cómo se aplica |
|---|---|
| Editar un config del repo (`hypr`, `kitty`, `zsh`, …) | Nada: son symlinks vivos a `~/.dotfiles`. Para Hyprland, `hyprctl reload` |
| Añadir o quitar un paquete | Editar `nix/home/packages.nix` o `nix/system/packages.nix` → `sudo nixos-rebuild switch --flake ~/.dotfiles#laptop` |
| Cambiar algo del sistema (servicios, greeter, portales) | Editar `nix/system/*.nix` → mismo `nixos-rebuild switch` |
| Actualizar todo | `nix flake update --flake ~/.dotfiles && sudo nixos-rebuild switch --flake ~/.dotfiles#laptop` |
| Probar sin activar | `sudo nixos-rebuild test --flake ~/.dotfiles#laptop` (no toca el bootloader) |
| Deshacer | `sudo nixos-rebuild switch --rollback`, o elegir otra generación en el menú de arranque |
| Ajustes de noctalia → repo | `noctalia-backup` (igual que en Arch) |
| Limpiar generaciones viejas | Automático: `nix.gc` semanal, borra lo de más de 30 días |

**Dónde tocar qué:**

```
nix/hosts/laptop/     arranque, locale, usuario, ajustes de nix
nix/system/desktop.nix    hyprland, portales, noctalia, fuentes, temas, zsh
nix/system/greeter.nix    greetd + noctalia-greeter
nix/system/services.nix   pipewire, udisks2, bluetooth
nix/system/packages.nix   paquetes del sistema
nix/home/dotfiles.nix     los symlinks a ~/.dotfiles
nix/home/packages.nix     paquetes del usuario
```

### Por qué los dotfiles no viven en `/nix/store`

`nix/home/dotfiles.nix` usa `mkOutOfStoreSymlink`, así que `~/.config/kitty`
apunta a `~/.dotfiles/kitty/.config/kitty` y **no** a un symlink de solo lectura
del store. Es a propósito: noctalia reescribe en runtime
`kitty/themes/noctalia.conf`, `btop/themes/noctalia.theme`,
`yazi/flavors/noctalia.yazi/`, `~/.config/hypr/noctalia.lua` y la región
`[palettes.noctalia]` dentro de `starship.toml`; y btop reescribe su propio
`btop.conf` al salir. Contra el store, todas esas escrituras fallarían.

Dos consecuencias:

- Los temas que genera noctalia caen **dentro del repo** y aparecen en
  `git status`. Eso es lo esperado, no es basura que haya que revertir.
- **`~/.dotfiles` es una dependencia del entorno.** Si borras o mueves el repo,
  los configs quedan colgando. No lo muevas sin actualizar `dotfiles.nix`.

---

## Troubleshooting

**El greeter no ofrece ninguna sesión.**
Comprueba que existe `/run/current-system/sw/share/wayland-sessions/hyprland.desktop`.
Lo garantiza `environment.pathsToLink` en `nix/system/desktop.nix`: NixOS no
enlaza ese directorio por defecto, y greetd arranca con un entorno vacío, así
que `XDG_DATA_DIRS` no ayuda. Lista lo que ve el greeter con
`noctalia-greeter sessions`; si la etiqueta no es `Hyprland`, ajusta
`session.default` en `nix/system/greeter.nix`.

**Me quedo sin entorno gráfico y no puedo entrar.**
En el menú de arranque elige una generación anterior. Desde una TTY
(`Ctrl+Alt+F2`), `sudo nixos-rebuild switch --rollback`.

**Hyprland arranca sin keybinds.**
`hyprctl configerrors` — vacío significa que carga bien. Si `~/.dotfiles` no
está clonado, `~/.config/hypr/conf.d` es un symlink roto y no hay config que
cargar.

**El tema del greeter no cambia.**
Revisa que `/var/lib/noctalia-greeter/greeter.toml` **no** tenga un bloque
`[appearance.palette]`. Si lo tiene, alguien lo declaró en
`nix/system/greeter.nix` y está ganando sobre el sync del shell.

**El selector de ficheros abre un diálogo GTK en vez de kitty+yazi.**
`~/.config/xdg-desktop-portal/hyprland-portals.conf` debe fijar
`org.freedesktop.impl.portal.FileChooser=termfilechooser`, y la ruta absoluta de
`yazi-wrapper.sh` en el config de termfilechooser tiene que existir:
`ls /run/current-system/sw/share/xdg-desktop-portal-termfilechooser/`.

**El sonido se corta al usar el micrófono por Bluetooth.**
Es el cambio de perfil A2DP → HSP/HFP de WirePlumber, no un fallo. Está dejado
así a propósito; ver `CLAUDE.md` §8.

**Las teclas de volumen no responden.**
El shell está caído: `pgrep noctalia`. Se arregla levantando noctalia, no
tocando los binds — `conf.d/keybinds.lua` las enruta por `noctalia msg` para
que salga su OSD.

**Un binario descargado a mano no arranca** (`No such file or directory` sobre
un ejecutable que sí existe). Espera `/lib64/ld-linux-x86-64.so.2`, que en NixOS
no existe. Usa el paquete de nixpkgs, o un `nix-shell`/devShell. Esta config
no activa `nix-ld`, y por eso SDKMAN se eliminó del `.zshrc`.
