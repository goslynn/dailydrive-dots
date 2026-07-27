-- XWayland — nitidez en pantalla con escalado fraccional
--
-- Por defecto, en un monitor con scale fraccional (eDP-1 @ 1.25) Hyprland dibuja
-- las apps X11 a tamaño lógico y luego las amplía como bitmap → texto borroso.
-- force_zero_scaling hace que rendericen a píxel físico nativo (nítidas); cada
-- toolkit se encarga entonces de su propio escalado de UI vía variables de entorno.
--
-- Apps Qt/GTK afectadas (p. ej. Sioyek) deben exportar su factor de escala; ver el
-- wrapper ~/.local/bin/sioyek. Si en el futuro abres otras apps XWayland y salen
-- diminutas, añádeles QT_AUTO_SCREEN_SCALE_FACTOR / GDK_SCALE igual que al wrapper.

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
