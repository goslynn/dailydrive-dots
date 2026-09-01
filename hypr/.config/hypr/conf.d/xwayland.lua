-- XWayland — nitidez en pantalla con escalado fraccional
--
-- Por defecto, en un monitor con scale fraccional (eDP-1 @ 1.25) Hyprland dibuja
-- las apps X11 a tamaño lógico y luego las amplía como bitmap → texto borroso.
-- force_zero_scaling hace que rendericen a píxel físico nativo (nítidas); cada
-- toolkit se encarga entonces de su propio escalado de UI.

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Xft.dpi — cómo se enteran las apps X11 de cuánto tienen que escalar
--
-- Con force_zero_scaling activo, XWayland les entrega la resolución física y
-- 96 DPI. Sin corregir eso, TODA app X11 se dibuja al 1/1.25 = 80% del tamaño
-- correcto, que es justo por lo que existía el wrapper de Sioyek
-- (nix/pkgs/sioyek-hidpi.nix) con sus QT_*_SCALE_FACTOR.
--
-- El recurso X `Xft.dpi` es la vía general, y no requiere un wrapper por app:
--
--   Qt6/xcb        lee Xft.dpi como DPI lógico y, con QT_ENABLE_HIGHDPI_SCALING
--                  (activo por defecto en Qt6), sale un devicePixelRatio 1.25.
--   GTK3/X11       lo usa para escalar la tipografía. Los widgets se quedan a
--                  escala 1 — GTK solo admite factores enteros (GDK_SCALE) y
--                  ése además contaminaría a las apps GTK en Wayland.
--   Chromium/X11   lo toma vía gtk-xft-dpi como device scale factor.
--
-- Por qué aquí y no en env.lua: Xft.dpi es un recurso del servidor X, no una
-- variable de entorno, así que no puede afectar a los clientes Wayland — que es
-- exactamente lo que se quiere. Las apps X11 lo leen al arrancar, de modo que
-- esto solo alcanza a las que se lancen después.
--
-- El valor sale del scale real del monitor en vez de estar escrito a mano, para
-- que no haya que tocarlo si conf.d/monitors.lua cambia.

local function apply_xft_dpi()
    local monitors = hl.get_monitors()
    local scale = 1.0

    for _, m in ipairs(monitors) do
        if m.focused then
            scale = m.scale
            break
        end
    end
    if scale == 1.0 and monitors[1] then
        scale = monitors[1].scale
    end

    local dpi = math.floor(96 * scale + 0.5)

    -- hl.exec_cmd pasa por `sh -c`, de ahí que la tubería funcione. El bucle es
    -- por si XWayland todavía no acepta conexiones en el instante de
    -- hyprland.start; si aun así falla, lo único que pasa es que las apps X11
    -- salen pequeñas (xrdb viene de nix/system/packages.nix).
    hl.exec_cmd(string.format(
        "for i in 1 2 3 4 5; do printf 'Xft.dpi: %d\\n' | xrdb -merge && break; sleep 1; done",
        dpi
    ))
end

hl.on("hyprland.start", apply_xft_dpi)

-- Un monitor externo con otro scale cambia el valor correcto. Solo afecta a las
-- apps X11 que se abran a partir de ese momento; las ya abiertas no releen.
hl.on("monitor.added", apply_xft_dpi)
