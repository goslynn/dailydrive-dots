# dotfiles

Setup minimalista de Hyprland (Wayland) en Arch. Toda la configuración vive
aquí y se aplica al `$HOME` con [GNU stow](https://www.gnu.org/software/stow/).

---

## Índice

- [Flujo stow](#flujo-stow)
- [Paquetes incluidos](#paquetes-incluidos)
- [Cómo modificar cada herramienta](#cómo-modificar-cada-herramienta)
- [Noctalia (shell)](#noctalia-shell)
- [Monitores](#monitores)
- [Theming (Catppuccin Mocha)](#theming-catppuccin-mocha)
- [Wallpaper](#wallpaper)
- [Discos extraíbles (USB)](#discos-extraíbles-usb)
- [Keybindings](#keybindings)
- [Screenshots](#screenshots)
- [Servicios en autostart](#servicios-en-autostart)
- [Troubleshooting](#troubleshooting)

---

## Flujo stow

Cada subdirectorio de `~/.dotfiles/` es un **paquete stow** con la estructura
que reproduce su destino en `$HOME`:

```
~/.dotfiles/
├── hypr/
│   └── .config/
│       └── hypr/
│           ├── hyprland.lua
│           └── conf.d/
├── kitty/
│   └── .config/
│       └── kitty/
│           └── kitty.conf
└── ...
```

Al correr `stow -t ~ hypr`, stow crea el symlink `~/.config/hypr →
~/.dotfiles/hypr/.config/hypr`. Editar los archivos en `~/.dotfiles/` o en
`~/.config/` es equivalente: son el mismo archivo.

**Aplicar todos los paquetes:**

```bash
cd ~/.dotfiles
for p in */; do
    [ "${p%/}" = "noctalia" ] && continue   # backup, no se stowea (ver abajo)
    stow -t "$HOME" "${p%/}"
done
```

**Re-aplicar un paquete (tras añadir archivos):**

```bash
cd ~/.dotfiles && stow -R -t "$HOME" hypr
```

**Desaplicar:**

```bash
cd ~/.dotfiles && stow -D -t "$HOME" hypr
```

**Añadir una nueva herramienta** (ejemplo `foo`):

```bash
mkdir -p ~/.dotfiles/foo/.config/foo
mv ~/.config/foo/* ~/.dotfiles/foo/.config/foo/
rmdir ~/.config/foo
cd ~/.dotfiles && stow -t "$HOME" foo
```

---

## Paquetes incluidos

| Paquete       | Qué contiene                                       |
|---------------|----------------------------------------------------|
| `hypr`        | Hyprland — `hyprland.lua` + `conf.d/` (config en Lua) |
| `scripts`     | `~/.local/bin/`: `sioyek` (escalado XWayland), `noctalia-backup` |
| `themes`      | Paleta Catppuccin Mocha (fuente única)             |
| `kitty`       | Terminal                                           |
| `nvim`        | Editor                                             |
| `git`         | Git config                                         |
| `starship`    | Prompt                                             |
| `zsh`         | Shell: `.zshrc`, `.zshenv` y módulos (ZDOTDIR en `~/.config/zsh`) |
| `yazi`        | File manager TUI + plugin `mount` (discos extraíbles) |
| `btop` `mpv`  | Monitor de sistema, reproductor                    |
| `easyeffects` | Procesador de audio                                |
| `sioyek`      | Lector de PDF                                      |
| `brave`       | Flags de arranque (Wayland/ozone)                  |
| `xdg-misc`    | Ficheros sueltos de `~/.config` (MIME, Qt)         |
| `noctalia`    | **No se stowea** — copia de la config del shell, ver [Noctalia](#noctalia-shell) |

> La config del shell (barra, notificaciones, launcher…) la escribe noctalia
> fuera de stow; aquí solo hay un volcado que genera `noctalia-backup`.
> Ver [Noctalia](#noctalia-shell).

---

## Cómo modificar cada herramienta

### Hyprland — `~/.config/hypr/`

Desde Hyprland 0.55 la config se escribe en **Lua** (`hyprland.lua`); hyprlang
(`hyprland.conf`) está deprecado. Si existen ambos, gana el `.lua`.

La config está **modularizada** en `conf.d/`. El entry point `hyprland.lua`
solo hace `require` en el orden correcto:

```
hyprland.lua             # entry point (package.path + requires)
conf.d/
├── monitors.lua         # hl.monitor + hotplug (reemplaza a shikane)
├── env.lua              # hl.env
├── programs.lua         # módulo de datos: terminal, browser, file_manager
├── xwayland.lua         # xwayland{}
├── style.lua            # general/decoration/animations
├── layout.lua           # dwindle/master/misc
├── input.lua            # input/touchpad/gestures
├── autostart.lua        # hl.on("hyprland.start", ...)
├── rules.lua            # hl.window_rule
└── keybinds.lua         # hl.bind
```

**Gotcha de `require`:** Lua traduce cada `.` del nombre de módulo a `/`, así
que `require("conf.d/style")` busca `conf/d/style.lua` y falla — y pasarle una
ruta absoluta tampoco sirve (también le traduce los puntos de `.config`/`.lua`).
Por eso `hyprland.lua` mete `conf.d/` en `package.path` y los ficheros se
requieren por nombre pelado (`require("style")`).

`programs.lua` es un **módulo de datos**: devuelve una tabla en vez de llamar a
`hl.*`, y lo consume quien lo necesita (`local programs = require("programs")`).
Es el reemplazo de las variables `$terminal` de hyprlang, que en Lua no
existen porque cada `require` es su propio scope.

Aplicar cambios sin reiniciar: `hyprctl reload`. Ver errores:
`hyprctl configerrors` (vacío = todo bien).

> **Ojo al probar cambios grandes:** `hyprctl reload` recarga *el fichero con el
> que arrancó la sesión*. Para validar una config nueva sin tocar la sesión
> viva, lanza una instancia anidada:
> `Hyprland -c ~/.config/hypr/hyprland.lua` y consúltala con
> `HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl configerrors`.

**Autocompletado / LSP:** Hyprland instala stubs de la API en
`/usr/share/hypr/stubs/hl.meta.lua`. Para que lua-ls los cargue, un
`.luarc.json` con `{"workspace":{"library":["/usr/share/hypr/stubs"]}}`.

### Kitty / Nvim / btop / mpv

Configuraciones tuyas pre-existentes; ya están bajo stow sin modificar.

### Zsh — `~/.config/zsh/`

El `ZDOTDIR` apunta a `~/.config/zsh`, así que zsh lee toda su config desde ahí
en vez de `~/`. La config está **modularizada**: `.zshrc` carga los módulos con
`source "$ZDOTDIR/<archivo>"`.

```
.zshenv          # XDG dirs, EDITOR, MANPAGER, GPG_TTY, PATH (se lee siempre, primero)
.zshrc           # history, opts, completion, zoxide; orquesta los source de abajo
fzf.zsh          # FZF_DEFAULT_* + picker Ctrl+F sin ocultos
aliases.zsh      # eza/bat/rg, git, lf, stream
bindings.zsh     # keybinds custom (palabra adelante/atrás, historial, etc.)
plugins.zsh      # gestor mínimo: clona y carga los plugins
prompt.zsh       # starship
plugins/         # clones git auto-instalados — NO versionados (.gitignore)
```

**Plugins:** `plugins.zsh` clona en `$ZDOTDIR/plugins/` la primera vez que
arrancas un shell (autosuggestions, history-substring-search,
fast-syntax-highlighting). Por eso `plugins/` está en `.gitignore`. Actualizar:
`zplugin-update`.

**Aplicar cambios:** abre una shell nueva, o `exec zsh` / `source ~/.config/zsh/.zshrc`.

> **⚠️ Bootstrap del sistema — paso manual fuera de stow.**
> Para que zsh use `ZDOTDIR`, hay un archivo **fuera de `$HOME`** que stow no
> puede gestionar: `/etc/zsh/zshenv`. La copia de referencia vive en
> `zsh/etc/zsh/zshenv` (no se despliega — está en `.stow-local-ignore`).
> Al reinstalar en una máquina nueva hay que copiarlo a mano con root:
>
> ```bash
> sudo install -Dm644 ~/.dotfiles/zsh/etc/zsh/zshenv /etc/zsh/zshenv
> ```

---

## Noctalia (shell)

Barra, notificaciones, launcher, clipboard, control center, OSDs, lockscreen,
screenshots y agente polkit corren en **noctalia** (`noctalia-git` 5.x, AUR).
Es un binario nativo — **no** usa quickshell.

### Su config: copia de seguridad, no fuente de verdad

noctalia v5 apila dos capas de config, y **la GUI solo escribe en la segunda**:

| Capa                                    | Quién la escribe                      |
|-----------------------------------------|---------------------------------------|
| `~/.config/noctalia/*.toml`             | tú, a mano (opcional; hoy no hay ninguno) |
| `~/.local/state/noctalia/settings.toml` | la GUI / `noctalia msg` — aquí está todo |

Por eso **noctalia no es un paquete stow**: un symlink en `~/.config/noctalia`
no se sobrescribiría al tocar ajustes —ese es el miedo habitual— sino algo
peor, se quedaría *tapado* por el state y desactualizado en silencio.

En su lugar, `noctalia-backup` vuelca la config **efectiva** (las dos capas
fusionadas, vía [`noctalia config export`](https://docs.noctalia.dev/v5/configuration/#exporting-config))
a `noctalia/.config/noctalia/config.toml`. Sentido único: sistema → repo. El
árbol imita `$HOME` como cualquier paquete, pero **no se stowea**; editar esa
copia a mano no cambia nada hasta que la restaures.

```bash
noctalia msg settings-open      # tocas lo que sea en la GUI
noctalia-backup                 # vuelca a este repo e imprime el diff
git -C ~/.dotfiles add noctalia && git commit
```

**Restaurar** (máquina nueva, o volver a un commit anterior):

```bash
pkill noctalia                                # con el shell vivo, el state se reescribe
mkdir -p ~/.config/noctalia
cp ~/.dotfiles/noctalia/.config/noctalia/config.toml ~/.config/noctalia/
rm -f ~/.local/state/noctalia/settings.toml   # si no, sus valores tapan la copia
noctalia config validate                      # debe decir "Config is valid"
setsid -f noctalia > /tmp/noctalia.log 2>&1   # o simplemente relogin
```

Lo que **no** guarda el export: los plugins descargados
(`~/.local/state/noctalia/plugins/`) y las plantillas community — pero sí sus
IDs (`[plugins] enabled`, `[theme.templates]`), así que noctalia los vuelve a
bajar solo.

Los `settings.json`, `colors.json` y `plugins.json` que quedan en
`~/.config/noctalia/` son restos del beta: ninguna versión actual los lee.
Se pueden borrar.

Reemplaza a `waybar` (barra), `mako` (notificaciones), `quickshell`/minshell
(shell anterior), `fuzzel` (launcher y picker de clipboard), `nm-applet`
(red), `polkit-gnome` (autenticación) y `grim`/`slurp` (captura) — todos
desinstalados.

**Arranque:** `hl.exec_cmd("noctalia")` dentro del handler
`hyprland.start` de `conf.d/autostart.lua`. Como los viejos `exec-once`, ese
evento **no** se dispara con `hyprctl reload`.

**IPC** — `noctalia msg <cmd>`; `noctalia msg --help` lista todo. Los que están
cableados a keybinds:

| Comando                                | Bind            |
|----------------------------------------|-----------------|
| `panel-toggle launcher`                | `SUPER + SPACE` |
| `panel-toggle clipboard`               | `SUPER + V`     |
| `panel-toggle control-center`          | `SUPER + D`     |
| `panel-toggle session` (menú de energía) | `SUPER + ESC` |
| `settings-toggle`                      | `SUPER + C`     |
| `screenshot-region` / `-fullscreen`    | ver [Screenshots](#screenshots) |
| `volume-*`, `brightness-*`, `media *`  | teclas `XF86*`  |

Útiles sin bind: `session <lock\|suspend\|logout\|reboot\|shutdown>` (el menú de
energía ya cubre esto interactivamente), `window-switcher`, `wallpaper-set`,
`nightlight-toggle`, `caffeine-toggle`, `status` (estado en JSON).

**Ver logs:** `noctalia msg log-level-set debug`, o relanzarlo en foreground
(`pkill noctalia && noctalia`).

---

## Monitores

Los gestiona **Hyprland directamente** desde `conf.d/monitors.lua`. Antes esto
lo hacía `shikane` como daemon aparte; ya no está instalado, porque la config
Lua expresa la misma regla de forma nativa y sin segunda fuente de verdad.

Hardware de esta máquina:

| Output     | Qué es                                        |
|------------|-----------------------------------------------|
| `eDP-1`    | Panel del laptop, 2560x1600@60, scale 1.25    |
| `HDMI-A-1` | Puerto externo, scale 1.25                    |

**Comportamiento** (idéntico a los profiles de shikane):

- HDMI conectado → solo el externo, panel del laptop apagado.
- HDMI desconectado → solo el panel del laptop.

Se implementa con `hl.on("monitor.added"/"monitor.removed", ...)`, que
habilita/deshabilita `eDP-1` según haya o no externo. El panel del laptop solo
se apaga cuando el externo está realmente presente, así que no hay camino que
deje todas las salidas apagadas.

**Añadir un display nuevo:**

1. Conéctalo y mira `hyprctl monitors all` — copia el nombre del output.
2. Añade un `hl.monitor({ output = "...", ... })` en `monitors.lua`.
3. `hyprctl reload`.

---

## Theming (Catppuccin Mocha)

Todos los colores viven en `~/.config/themes/catppuccin/mocha/`:

| Archivo          | Lo consume                                          |
|------------------|------------------------------------------------------|
| `tokens.conf`    | Referencia humana — paleta canónica (no la lee nadie)|
| `hyprland.lua`   | `conf.d/style.lua` vía `dofile()`                    |
| `kitty.conf`     | `~/.config/kitty/kitty.conf` vía `include`           |

`hyprland.lua` es un módulo Lua que **devuelve una tabla** de colores
(`{ blue = "rgb(89b4fa)", ... }`). `style.lua` lo carga con `dofile()` —y no
con `require`— porque vive fuera del árbol de `hypr/` y su nombre chocaría con
el entry point como nombre de módulo.

Los colores de noctalia ya no se mapean a mano (el viejo `colors.json` está
muerto): usa su paleta *builtin* Catppuccin y desde ahí **genera** ficheros de
tema, según `[theme.templates]` en su config:

| Genera                              | ¿Cae en el repo? |
|-------------------------------------|------------------|
| `kitty/themes/noctalia.conf`        | Sí (dir stoweado) |
| `btop/themes/noctalia.theme`        | Sí (dir stoweado) |
| `starship.toml` → `[palettes.noctalia]` | Sí (fichero stoweado) |
| `~/.config/hypr/noctalia.lua`       | **No** — ver aviso |

Es decir: al cambiar de tema aparecen cambios en `git status` sin que tú hayas
tocado nada. Es esperado.

> [!WARNING]
> `hyprland.lua` hace `require("noctalia").apply_theme()`, pero
> `~/.config/hypr/noctalia.lua` lo genera noctalia y **no está en este repo**
> (stow desplegó `hypr/` por-fichero, así que el generado se quedó fuera). En
> una máquina limpia hay que arrancar noctalia una vez para que exista.

La paleta de `~/.config/themes/` sigue siendo la fuente para Hyprland. No hay
motor de templates externo (matugen y compañía están descartados a propósito).

**Para cambiar de theme:** reemplaza el contenido de estos archivos manteniendo
nombres y formatos. Después: `hyprctl reload`.

No hay multi-theming ni cambio en vivo — el switch es manual y único.

---

## Wallpaper

Lo gestiona **noctalia**: imágenes con su picker de wallpaper integrado,
vídeo con el plugin oficial **mpvpaper** (`mpv`/`mpvpaper` en PATH). No hay
daemon aparte en `autostart.lua` — vive dentro del propio proceso de noctalia.

La galería es `~/Pictures/Wallpapers/` (imágenes y vídeo mezclados; no vive en
este repo, es contenido de usuario, no config). Ambos pickers apuntan ahí:

- Imágenes: `Settings → Wallpaper` — carpeta de origen, y ahí mismo se activan
  `Wallpaper` y el widget de barra si se quieren.
- Vídeo: `Settings → Plugins → Video Wallpaper` (mpvpaper) — campo
  **Video directory**; por defecto es `~/Videos`, hay que cambiarlo.

Cambiar el wallpaper:

```sh
noctalia msg wallpaper-set [connector] <path>   # imagen concreta, persiste
noctalia msg wallpaper-next|previous|random [connector]
noctalia msg panel-toggle noctalia/mpvpaper:picker   # picker de vídeo
```

Sustituye a **waypaper-engine** (AUR): tenía su propia galería/DB en
`~/.config/waypaper-engine/` y un daemon de arranque (`waypaper-daemon`),
ya quitado de `autostart.lua`. Su galería se migró a `~/Pictures/Wallpapers/`;
el paquete se puede desinstalar (`pacman -Rns waypaper-engine`) una vez se
confirme que el picker de noctalia funciona.

### Theme fijo, no ligado al wallpaper

El theme es Catppuccin Mocha fijo (`theme.source = "builtin"`,
`theme.builtin = "Catppuccin"` en `settings.toml`) — cambiar de wallpaper
**no** debe cambiar la paleta. Dos trampas del picker de wallpaper que sí la
cambian, a evitar:

- **`theme.source = "wallpaper"`** genera una paleta nueva del wallpaper cada
  vez que cambia. No usar — mantener `source` en `builtin`.
- **Favoritos (★)**: marcar como favorito un wallpaper mientras está aplicado
  guarda junto a la ruta el `theme_mode`/paleta activos en ese momento
  (`[[wallpaper.favorite]]` en `settings.toml`), y volver a seleccionar ese
  favorito reaplica ese theme entero, no solo la imagen. Si se favorita algo,
  revisar que la entrada en `settings.toml` no tenga `palette_source` /
  `builtin_palette` / `community_palette` — solo `path` y `theme_mode = "dark"`.

Para forzar el theme fijo por CLI sin tocar la GUI:

```sh
noctalia msg color-scheme-set builtin Catppuccin
noctalia msg theme-mode-set dark
noctalia msg templates-apply
```

---

## Discos extraíbles (USB)

**No hay automount.** Nada se monta solo al pinchar un USB — es deliberado, no
falta un daemon. El dueño del montaje es **udisks2**, y se maneja desde yazi.

### Desde yazi (la forma normal)

Abre yazi (`SUPER + F`) y pulsa **`M`**. Se abre el panel del plugin
`mount.yazi` con todas las particiones del sistema:

| Tecla | Acción                         |
|-------|--------------------------------|
| `j` / `k` | Bajar / subir              |
| `m`   | Montar la partición            |
| `u`   | Desmontar                      |
| `e`   | Expulsar el disco (apaga el puerto) |
| `l`   | Entrar en el punto de montaje  |
| `q`   | Salir del panel                |

udisks2 monta en `/run/media/vgonz/<ETIQUETA>` (o el UUID si el disco no tiene
etiqueta). Al ser sesión local activa, polkit lo autoriza sin pedir contraseña.

**Desmonta siempre antes de tirar del USB** (`u` o `e`). FAT32 no tiene journal:
sacarlo con escrituras en vuelo corrompe la tabla.

### Desde la terminal

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT   # ver qué hay
udisksctl mount   -b /dev/sda1               # montar
udisksctl unmount -b /dev/sda1               # desmontar
udisksctl power-off -b /dev/sda              # expulsar (el disco, no la partición)
```

### Identificar el dispositivo correcto

**`/dev/sdX` no es estable y no tiene relación con el puerto físico.** El kernel
reparte `sda`, `sdb`… por orden de sondeo. El mismo pendrive en el mismo puerto
sale `sda` un día y `sdb` otro si algo llegó antes. Nunca escribas ni formatees
apuntando a `/dev/sdX` sin comprobar antes qué es:

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT   # qué hay y cómo se llama
ls -l /dev/disk/by-label/                         # por etiqueta  ← usa esto
ls -l /dev/disk/by-uuid/                          # por volume serial
ls -l /dev/disk/by-id/                            # por serial USB del fabricante
ls -l /dev/disk/by-path/                          # por puerto físico
```

`by-path` es el único atado al puerto (`pci-…-usb-0:1:…`): identifica *dónde*
está pinchado, no *qué* está pinchado. Útil para "el disco del puerto de atrás",
inútil para "mi pendrive de backups".

**Los pendrives baratos mienten o duplican el serial.** Los de VID genérico
(strings tipo `USB` / `Disk 2.0`) suelen traer el mismo serial en todo un lote,
o ninguno. Si dos comparten serial, udev genera el **mismo** nombre en `by-id`
y el symlink acaba apuntando solo a uno. El volume serial de FAT32 tampoco
salva: son 32 bits derivados de fecha+hora de formateo, y un lote formateado en
fábrica de una tirada puede repetirlo.

Conclusión: **para varios pendrives iguales, la etiqueta es el único
identificador fiable, porque la pones tú.** Ponle a cada uno una distinta y
márcalos físicamente igual.

### Formatos y encoding

FAT32 y exFAT guardan los nombres largos en UTF-16 por especificación. **La
opción de montaje que decide si eso viaja bien es `utf8`, no `iocharset`**, y
udisks2 la pone siempre. Con el locale `en_US.UTF-8` de esta máquina los
acentos, las ñ y hasta el japonés hacen round-trip byte a byte — verificado
sobre este pendrive.

`iocharset` solo gobierna los nombres cortos 8.3 cuando `utf8` está activo, así
que ver `iocharset=ascii` en la lista de `findmnt` no es un problema: es el
valor por defecto del kernel, inerte. Aparece igual en el montaje del USB y en
el de `/boot`, y ninguno de los dos destroza nada. El mojibake haría falta un
montaje **sin** `utf8` y con un `iocharset` no-UTF-8 — no es el caso aquí ni hay
que tocar nada para evitarlo.

`exfat` no tiene ni opción `iocharset` — su driver habla UTF-8 siempre.

Al formatear uno nuevo:

| Filesystem | Cuándo                                                       |
|------------|--------------------------------------------------------------|
| **FAT32**  | Solo si todos los ficheros son < 4 GiB. Lo lee absolutamente todo (hardware viejo, firmware UEFI). |
| **exFAT**  | **Por defecto para cualquier cosa con vídeo o ISOs.** Sin límite práctico de tamaño. Win Vista SP1+, macOS 10.6.5+, Linux 5.4+, Android 13+. |
| **ext4**   | Solo para uso exclusivo en este PC. Ilegible fuera de Linux. |

> **El límite de 4 GiB de FAT32 falla en silencio.** Al copiar un fichero mayor,
> el gestor de ficheros (yazi incluido) puede terminar sin error visible y dejar
> el destino **truncado a exactamente 4 294 967 295 bytes** (`2^32 - 1`). Un
> `.mkv` cortado así se abre y se reproduce con normalidad — simplemente se
> acaba antes de tiempo — así que la inspección visual no lo detecta. Si ves ese
> número exacto como tamaño de fichero, es esto.

### Validar una copia

Nunca te fíes de "se ve todo". Compara nombres y tamaños, y el contenido de lo
grande:

```bash
# 1. estructura y tamaños
cd ~/origen && find . -type f -printf '%P\t%s\n' | sort > /tmp/src.txt
cd /run/media/vgonz/ETIQUETA && find . -type f -printf '%P\t%s\n' | sort > /tmp/dst.txt
diff /tmp/src.txt /tmp/dst.txt        # vacío = mismos ficheros, mismos bytes

# 2. contenido byte a byte (lento en USB 2.0: ~30 MB/s de techo)
cmp origen/fichero /run/media/vgonz/ETIQUETA/fichero && echo IDÉNTICO
```

Para copiar, mejor `rsync -a --info=progress2 ~/origen/ /run/media/vgonz/ETIQUETA/destino/`:
da código de salida fiable y es reanudable, a diferencia del copiar/pegar de la TUI.

```bash
sudo mkfs.vfat -F 32 -n ETIQUETA /dev/sdX1   # FAT32 (etiqueta: 11 chars, mayúsculas)
sudo mkfs.exfat -n etiqueta /dev/sdX1        # exFAT
sudo fatlabel /dev/sdX1 ETIQUETA             # renombrar FAT32 sin formatear (desmontado)
fatlabel /dev/sdX1                           # leer la etiqueta actual
```

`fatlabel` escribe 11 bytes en dos sitios (el BPB del boot sector y una entrada
de volumen en el directorio raíz) y no toca ni los datos ni el volume serial.
La etiqueta se codifica en **codepage 850**, no en UTF-8: nada de acentos ni ñ
ahí, aunque en los nombres de fichero vayan perfectos. `by-label` no refleja el
cambio hasta que repinchas o corres `sudo udevadm trigger`.

---

## Keybindings

`SUPER` = tecla Windows. Todo vive en `conf.d/keybinds.lua`.

### Apps

| Bind                | Acción                          |
|---------------------|---------------------------------|
| `SUPER + SPACE`     | **App launcher** (noctalia)     |
| `SUPER + T`         | Terminal (kitty)                |
| `SUPER + F`         | File manager (yazi en kitty — default system-wide) |
| `SUPER + B`         | Browser (brave)                 |
| `SUPER + V`         | Clipboard history (noctalia)    |
| `SUPER + D`         | Control center (noctalia)       |
| `SUPER + C`         | Configuración (noctalia settings) |
| `SUPER + ESC`       | Menú de energía (lock/suspend/logout/reboot/shutdown) |
| `SUPER + M`         | Salir de Hyprland               |

Yazi está registrado como default de `inode/directory` vía `~/.config/mimeapps.list`,
así que `xdg-open <dir>` desde cualquier app también lo abre.

### Ventanas

| Bind                       | Acción                          |
|----------------------------|---------------------------------|
| `SUPER + Q`                | Cerrar ventana activa           |
| `SUPER + W`                | Toggle floating                 |
| `SUPER + SHIFT + F`        | Maximizar (con barras)          |
| `SUPER + CTRL + F`         | Fullscreen total                |
| `SUPER + J`                | Toggle split direction (dwindle)|
| `SUPER + P`                | Pseudotile                      |
| `SUPER + LMB` (drag)       | Mover ventana                   |
| `SUPER + RMB` (drag)       | Redimensionar                   |
| `SUPER + CTRL + flechas`   | Redimensionar 30px              |

### Focus / movimiento

| Bind                          | Acción                       |
|-------------------------------|------------------------------|
| `SUPER + h/j/k/l` o flechas   | Mover foco                   |
| `SUPER + SHIFT + flechas`     | Mover ventana en el tile     |

### Workspaces

| Bind                       | Acción                          |
|----------------------------|---------------------------------|
| `SUPER + 1..9, 0`          | Ir a workspace 1..10            |
| `SUPER + SHIFT + 1..9, 0`  | Mover ventana a workspace       |
| `SUPER + mouse wheel`      | Ciclar workspaces               |
| `SUPER + ` ` (backtick)    | Scratchpad toggle               |
| `SUPER + SHIFT + ` `       | Mover ventana al scratchpad     |

### Multimedia (teclas dedicadas)

Todas pasan por noctalia, así que levantan su OSD:

| Tecla                         | Acción                       |
|-------------------------------|------------------------------|
| `XF86AudioRaise/Lower/Mute`   | Volumen sistema              |
| `XF86AudioMicMute`            | Mute micrófono               |
| `XF86MonBrightnessUp/Down`    | Brillo pantalla              |
| `XF86AudioNext/Prev/Play`     | Control reproductor          |

---

## Screenshots

Los captura **noctalia** con su propio `zwlr_screencopy` — ya no hay script ni
`grim`/`slurp`.

| Bind                          | Modo                                    |
|-------------------------------|-----------------------------------------|
| `SUPER + SHIFT + S`           | Selección de región                     |
| `SUPER + S` o `Print`         | Monitor enfocado                        |
| `SUPER + SHIFT + ALT + S`     | Todas las salidas                       |

**Anotaciones:** no son un bind aparte. Noctalia soporta un editor externo
(`satty`, que sigue instalado) configurable en
Settings → *screenshot annotation tool*; una vez puesto, envuelve cualquier
captura. Ajustar ahí también el directorio de destino.

---

## Servicios en autostart

Lanzados desde el handler `hl.on("hyprland.start", ...)` de `conf.d/autostart.lua`:

| Proceso                      | Función                              |
|------------------------------|--------------------------------------|
| `noctalia`                   | Shell completo — ver [Noctalia](#noctalia-shell) |
| `wl-paste ... cliphist`      | Captura clipboard a histórico (x2: texto e imagen) |

Ese evento solo se dispara al **inicio de sesión**, no en `hyprctl reload`.
Para relanzar uno manualmente: `pkill <proc> && setsid -f <proc> &`.

Ya no arrancan: `shikane` (monitores ahora en `monitors.lua`), `qs`
(quickshell), `nm-applet` y `polkit-gnome` (ambos los cubre noctalia).

---

## Troubleshooting

- **Errores de config Hyprland**: `hyprctl configerrors` (vacío = todo bien).
  Si un `require` falla, el error dice exactamente qué rutas intentó.
- **Un cambio en Lua no se aplica**: `hyprctl reload` recarga el fichero con el
  que arrancó la sesión. Si arrancaste con `hyprland.conf` y luego creaste
  `hyprland.lua`, la sesión viva sigue en el `.conf` hasta que reinicies sesión.
- **Noctalia no aparece / crashea**: `pkill noctalia && noctalia` en una
  terminal para ver stderr. Estado: `noctalia msg status`.
- **Notificaciones no llegan**: `pgrep -x noctalia` debe devolver PID (es el
  único daemon de notificaciones). Test: `notify-send hola`.
- **Pantalla negra al loguear**: revisa el log en
  `$XDG_RUNTIME_DIR/hypr/*/Hyprland.log`.
- **Texto borroso en apps X11 (p. ej. Sioyek)**: con el monitor a scale
  fraccional (eDP-1 @ 1.25), Hyprland dibuja las apps XWayland a tamaño lógico y
  las amplía como bitmap → borrosas. Lo resuelve
  `xwayland { force_zero_scaling = true }` en `conf.d/xwayland.lua` (renderiza a
  píxel nativo) + las variables `QT_*` que cada app necesita para reescalar su
  UI. Sioyek las recibe vía el wrapper `~/.local/bin/sioyek` (paquete stow
  `scripts`). Si añades otra app XWayland que salga diminuta, dale
  `QT_AUTO_SCREEN_SCALE_FACTOR=1` / `GDK_SCALE` igual que el wrapper.
- **Backup pre-rice**: `~/dotfiles-backup-20260527-230822.tar.gz` — restaurar con
  `tar -xzf ... -C ~`.
