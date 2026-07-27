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
for p in */; do stow -t "$HOME" "${p%/}"; done
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
| `scripts`     | `~/.local/bin/sioyek` — wrapper de escalado XWayland |
| `themes`      | Paleta Catppuccin Mocha (fuente única)             |
| `kitty`       | Terminal                                           |
| `nvim`        | Editor                                             |
| `git`         | Git config                                         |
| `starship`    | Prompt                                             |
| `zsh`         | Shell: `.zshrc`, `.zshenv` y módulos (ZDOTDIR en `~/.config/zsh`) |
| `btop` `mpv`  | Monitor de sistema, reproductor                    |
| `easyeffects` | Procesador de audio                                |
| `sioyek`      | Lector de PDF                                      |
| `brave`       | Flags de arranque (Wayland/ozone)                  |
| `gtk-3.0` `gtk-4.0` `qt5ct` `qt6ct` `xdg-misc` | Theming/MIME de toolkits |

> La config del shell (barra, notificaciones, launcher…) **no** vive aquí:
> la gestiona noctalia en `~/.config/noctalia`. Ver [Noctalia](#noctalia-shell).

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
bindings.zsh     # cursores y keybinds de zsh-vi-mode (vía zvm_after_init)
plugins.zsh      # gestor mínimo: clona y carga los plugins
prompt.zsh       # starship
plugins/         # clones git auto-instalados — NO versionados (.gitignore)
```

**Plugins:** `plugins.zsh` clona en `$ZDOTDIR/plugins/` la primera vez que
arrancas un shell (autosuggestions, history-substring-search, vi-mode,
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

**Su config no está en este repo**: vive en `~/.config/noctalia/`
(`settings.json`, `colors.json`, `colorschemes/`, `plugins/`) y se edita desde
la GUI (`noctalia msg settings-open`), no a mano.

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
| `panel-toggle clipboard`               | `SUPER + C`     |
| `panel-toggle control-center`          | `SUPER + D`     |
| `screenshot-region` / `-fullscreen`    | ver [Screenshots](#screenshots) |
| `volume-*`, `brightness-*`, `media *`  | teclas `XF86*`  |

Útiles sin bind: `settings-open`, `session <lock\|suspend\|logout\|reboot\|shutdown>`,
`window-switcher`, `wallpaper-set`, `nightlight-toggle`, `caffeine-toggle`,
`status` (estado en JSON).

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

Los colores de noctalia son aparte: `~/.config/noctalia/colors.json`, mapeados
a mano desde `tokens.conf`. No hay motor de templates (matugen y compañía están
descartados a propósito).

**Para cambiar de theme:** reemplaza el contenido de estos archivos manteniendo
nombres y formatos. Después: `hyprctl reload`.

No hay multi-theming ni cambio en vivo — el switch es manual y único.

---

## Wallpaper

Lo gestiona **waypaper-engine** (AUR), con su propia galería/DB en
`~/.config/waypaper-engine/` — no hay fichero de wallpaper en este repo.

- El daemon (`waypaper-daemon`) arranca desde `conf.d/autostart.lua` y
  re-aplica el último wallpaper al iniciar sesión.
- Para cambiarlo, abre el picker gráfico: `waypaper-engine`.

Noctalia también sabe de wallpapers (`noctalia msg wallpaper-set|next|random`),
pero aquí el dueño es waypaper-engine: usar los dos a la vez se pisa.

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
| `SUPER + C`         | Clipboard history (noctalia)    |
| `SUPER + D`         | Control center (noctalia)       |
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
| `waypaper-daemon`            | Wallpaper                            |
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
