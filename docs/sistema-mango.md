# Sistema "mango": recuperación, blindaje y auditoría (noviembre 2026)

Registro de todo lo hecho entre el 2026-11-03 y el 2026-11-07 en la notebook **mango**: HP Victus 15-fa1xxx, Arch Linux, Hyprland, btrfs en `/dev/nvme0n1p6`.

**Cómo usar este documento:** las secciones 3 a 6 explican cómo funciona hoy el sistema. La sección 10 reúne los comandos de uso diario. La sección 2 explica por qué se hizo cada cosa.

---

## 1. Línea de tiempo

| Fecha | Qué pasó |
|---|---|
| 11-03 | Limpieza de disco y `pacman -Syu`. **La actualización murió a mitad por disco lleno (ENOSPC).** |
| 11-03 | El sistema no arranca: GRUB no encuentra el kernel. Se repara desde un USB live. Hyprland 0.57 ya no lee `.conf` y el rice "desaparece". |
| 11-03 | Downgrade a Hyprland 0.56.2 con pin (`IgnorePkg`). Se reparan la transacción cortada, las initramfs y GRUB. |
| 11-03 a 11-06 | Migración del rice de `.conf` a Lua, en las fases 0 a 4, con verificación automática y manual. |
| 11-06 | Balance de btrfs: la cantidad de espacio sin asignar pasa de 0 a 12 GiB. |
| 11-07 | **P1:** se separan subvolúmenes desde el USB live. **P3:** snapper, snap-pac y grub-btrfs. **P4:** prueba real de restauración. |
| 11-07 | **Fase 5:** se quita el pin y se actualiza a Hyprland 0.57.1. |
| 11-07 | Auditoría, bloques A a F: seguridad, errores, `.pacnew`, mantenimiento, paquetes y rice. |

## 2. El incidente del 2026-11-03 y sus lecciones

**Qué pasó:** `pacman -Syu` llenó el disco a mitad de la transacción. Antes de fallar, `60-mkinitcpio-remove` ya había borrado los kernels de `/boot`, y los hooks finales nunca corrieron. En ese momento el disco al 100% se diagnosticó como "todo bien", sin revisar por qué estaba lleno.

**Lecciones convertidas en mecanismos:**

| Lección | Mecanismo actual |
|---|---|
| Un update nunca debe empezar con poco espacio | Hook `/etc/pacman.d/hooks/00-espacio.hook` (sección 5) |
| Tiene que haber vuelta atrás si un update rompe el sistema | snapper + snap-pac + grub-btrfs + `snap-restore` (sección 4) |
| Si Hyprland se cae durante un update, mata a pacman | Las actualizaciones delicadas se hacen desde TTY (sección 5) |
| No dar por buena una actualización sin verificarla | `fase5-post.sh`: kernel↔módulos, initramfs, dkms y `verify-config` |
| `paccache -rk1` impidió el downgrade | `paccache.timer` con `-rk2` (sección 7) |
| Breaking changes (0.57 eliminó `.conf`) | Antes de actualizar: leer el changelog y validar la config con el binario nuevo extraído en una carpeta temporal |

## 3. Disco y subvolúmenes

Btrfs en `/dev/nvme0n1p6` (UUID `6b653c96-1329-487e-8f9a-9da0fd292508`). Desde P1 (2026-11-07) cada área vive en un subvolumen hermano, en el nivel superior. Así los snapshots de `@` no arrastran home ni Docker:

| Subvolumen | Montaje | Por qué separado |
|---|---|---|
| `@` | `/` | Es el sistema; lo único que se snapshotea |
| `@home` | `/home` | Tus datos no se revierten al restaurar |
| `@log` | `/var/log` | Los logs sobreviven a un rollback (para diagnosticar) |
| `@pkg` | `/var/cache/pacman/pkg` | La caché de paquetes no infla los snapshots |
| `@docker` | `/var/lib/docker` | Imágenes y volúmenes, muy cambiantes |
| `@containerd` | `/var/lib/containerd` | Unos 22 GB, muy cambiante |
| `@swap` | `/swap` | El swapfile de 4G, NOCOW (no se puede snapshotear) |
| `@snapshots` | `/.snapshots` | Donde snapper guarda los snapshots |

- **fstab:** el respaldo previo está en `/etc/fstab.pre-split`. Lo generó `~/Backups/btrfs-split/split.sh`, que se ensayó antes en un disco loop con `rehearse.sh`.
- **Partición VMs:** `~/VMs` es una partición ext4 aparte (`nvme0n1p5`).
- **Balance:** correrlo **solo** si el espacio sin asignar llega a cerca de 0, y de forma incremental (`-dusage=0/10/25/50`).
- **Subvolúmenes anidados:** los snapshots no los incluyen. Por eso, después de la prueba de P4, `var/lib/portables` y `var/lib/machines` son carpetas normales; no afecta, porque no se usan.

## 4. Snapshots y vuelta atrás

### Configuración (`snapper -c root`)
| Opción | Valor | Efecto |
|---|---|---|
| TIMELINE_CREATE | no | Sin snapshots por hora: solo de pacman o manuales |
| NUMBER_LIMIT | 4-10 | Se conservan hasta 10 snapshots normales |
| NUMBER_LIMIT_IMPORTANT | 2-5 | Hasta 5 snapshots importantes (kernel, nvidia, hyprland, grub, mkinitcpio, systemd) |
| FREE_LIMIT | 0.2 | Si quedan menos de 39G libres, se borra hasta el mínimo. No necesita quotas, siempre que NUMBER_LIMIT sea un rango |
| EMPTY_PRE_POST_CLEANUP | yes | Borra los pares pre/post que no cambiaron nada |
| ALLOW_USERS | zgreencat | `snapper list` y `snapper delete` sin sudo |

- **snap-pac:** crea un par pre/post en cada transacción de pacman. Los paquetes importantes están en `/etc/snap-pac.ini`.
- **grub-btrfs:** `grub-btrfsd` agrega cada snapshot al submenú "Arch Linux snapshots". El hook `grub-btrfs-overlayfs` de mkinitcpio permite arrancarlos en solo lectura, con los cambios en RAM.
- **`snapper-cleanup.timer`:** se ejecuta a diario. `snapper-timeline.timer` está deshabilitado (snapper 0.13 lo habilita solo al crear la config).

### Restaurar
1. **Si el sistema arranca:** `snapper list`, luego `sudo snap-restore <N>`, y reiniciar.
2. **Si no arranca:**
   - en GRUB, entra a "Arch Linux snapshots" y elige el snapshot;
   - una vez dentro, corre `sudo snap-restore <N>` y reinicia normal.

   Al arrancar un snapshot aparecen dos `[FAILED] systemd-remount-fs`. Es **esperado**, porque `/` es un overlay.

`snap-restore` está en `/usr/local/bin` y su fuente en `~/Backups/btrfs-split/p3/`:
- muestra la fecha y la descripción del snapshot y pide escribir `RESTAURAR`;
- renombra el `@` actual a `@roto-<fecha>` y crea un `@` nuevo desde el snapshot;
- si falla a mitad, deja `@` como estaba;
- avisa si `@` tiene subvolúmenes anidados.

Para borrar el `@roto` cuando todo esté bien:
```
sudo mount -o subvolid=5 /dev/nvme0n1p6 /mnt && sudo btrfs subvolume delete -R /mnt/@roto-<fecha> && sudo umount /mnt
```

- **Por qué no `snapper rollback`:** GRUB arranca con `rootflags=subvol=@` e ignora el subvolumen por defecto.
- **Qué revierte una restauración:** `/etc`, los paquetes y flatpak. **No** revierte home, logs, Docker ni la caché de pacman.

### Snapshots que conviene conservar
- **2:** "P3: base inicial".
- **6:** "Fase 5: antes de unpin", la vuelta atrás a Hyprland 0.56.2. Borrarlo con `snapper -c root delete 6` cuando 0.57 lleve unos días estable.
- **13:** "Auditoría A+B: antes".

## 5. Actualizar sin romper nada

**Hook anti-ENOSPC:** `/etc/pacman.d/hooks/00-espacio.hook` llama a `/usr/local/bin/pacman-espacio-check`.
- Aborta **instalaciones y actualizaciones** si quedan menos de 10 GiB libres o menos de 2 GiB sin asignar en btrfs.
- Desinstalar siempre está permitido, para poder liberar espacio.
- Los umbrales se pueden cambiar en `/etc/pacman-espacio.conf` (`MIN_FREE_GIB=`, `MIN_UNALLOC_GIB=`).

**Actualización normal:** `sudo pacman -Syu`. El hook revisa el espacio y snap-pac toma el snapshot automáticamente.

**Actualización delicada** (Hyprland, kernel, nvidia, mesa, systemd, grub). Los scripts están en `~/Backups/btrfs-split/p5/`:
1. Leer el changelog de los paquetes críticos que cambian de versión menor o mayor.
2. `sudo bash fase5-pre.sh`: comprueba el estado, crea un snapshot importante, corre `pacman -Sy` y lista los paquetes críticos.
3. Validar la config con el binario nuevo **antes** de instalarlo: descargar el `.pkg.tar.zst`, extraerlo en una carpeta temporal y correr `LD_LIBRARY_PATH=… Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.
4. **Desde TTY** (Ctrl+Alt+F3): `sudo pacman -Su`.
5. `sudo bash fase5-post.sh` **antes de reiniciar**. Revisa la transacción, que cada kernel coincida con sus módulos, las initramfs (con overlayfs), dkms, nvidia, `verify-config`, el par pre/post y los `.pacnew`.
6. Reiniciar solo si dice ✅.

Nunca uses `paccache -rk1` justo después de actualizar, porque impide hacer downgrade.

## 6. Hyprland y el rice

- **Hyprland 0.57.1** con la config en Lua. El pin se quitó el 2026-11-07; el respaldo de la config anterior es `/etc/pacman.conf.pre-fase5`.
- **Estructura:**
  - `hyprland.lua` carga `configs/{tags,looknfeel,animations,windowrules,input,keybinds}.lua`;
  - los colores están en `colors.lua`, que escribe `scripts/apply-theme.sh`;
  - solo `hypridle.conf`, `hyprlock.conf` y `hyprlock-colors.conf` siguen en formato hyprlang.
- **`scripts/hypr-do.sh`:** traduce acciones a `hyprctl eval` y falla si la respuesta no es `ok`. Hay que comprobarlo así porque hyprctl termina con código 0 aunque falle.
- **El repositorio:** el detalle de la migración está en `docs/lua-migration/`, y el último estado con `.conf` en el tag `pre-lua-migration`.

### Waybar: clic en workspaces (2026-11-08)
Con la config en Lua, 0.57 rechaza la sintaxis vieja `dispatch workspace N`, que es la que manda waybar 0.15 al hacer clic en un workspace. El clic dejaba de funcionar: daba `')' expected near '1'`. Hyprland considera que es comportamiento intencional, y waybar lo corrigió en el PR Alexays/Waybar#5013, que detecta si Hyprland usa Lua y manda `hl.dsp.focus(...)`.

- **Solución:** se instaló **`waybar-git` 0.16.0.r2** (desde AUR) en lugar de `waybar` 0.15.0. Antes, `playerctl` se marcó como instalado explícitamente, para que no quede huérfano.
- **Verificado:** el clic, el scroll, la bandeja, pulse, wireplumber, playerctl y upower funcionan.
- **Volver al paquete oficial** cuando `waybar` ≥ 0.16 llegue a `extra`: `sudo pacman -S waybar`, que reemplaza a waybar-git.
- **Advertencias inofensivas en el log:** `Failed to open bar ipc connection` (`"ipc": true` es solo para sway) y la altura de 32 a 35px.

### Cambios de atajos (auditoría F, 2026-11-07)
En Hyprland, **todos** los binds con la misma combinación se disparan a la vez. Había 17 combinaciones duplicadas:

| Atajo | Antes | Ahora |
|---|---|---|
| SUPER+P | pseudo-tile **y** project-launcher | project-launcher |
| SUPER+ALT+P | — | pseudo-tile |
| SUPER+SHIFT+M | `kitty yt` **y** meeting-mode | meeting-mode |
| SUPER+ALT+M | — | YouTube Music TUI (`kitty yt`) |
| SUPER+SHIFT+N | mover y seguir | **mover sin seguir** |
| SUPER+CTRL+N | mover y seguir (×2 o ×4) | mover y seguir (×1) |
| SUPER+ALT+SHIFT+1..5 | copia de CTRL+N | eliminado |
| multi-monitor (SUPER+SHIFT+H/L, ALT+flechas, CTRL+SHIFT+flechas) | se ejecutaba 2 veces | 1 vez |

Pasamos de 131 binds a 101, sin ningún duplicado. Las descripciones del visor (SUPER+TAB → Keybindings) también se corrigieron.

### Archivos retirados
- **Los `.conf` legados:** `hyprland.conf`, `configs/*.conf`, `colors.conf` y `colors-base.conf`.
- **Restos de otras herramientas:** `hyprpaper.conf` (el wallpaper es `awww`), matugen (su template estaba roto, usaba swww y nada lo invocaba) y 5 scripts viejos con sintaxis legacy.
- **Respaldo:** `~/Backups/auditoria/f-hypr-matugen-20261107-021450.tar.gz`.
- **2026-11-08:** se borraron también `omenu.sh` (SUPER+TAB usa `ags toggle omenu`), `theme-selector-preview.py` (solo lo usaba `omenu.sh`) y `theme-card.html`. Respaldo: `~/Backups/auditoria/scripts-sin-uso-*.tar.gz`.

## 7. Seguridad y servicios

| Área | Estado | Archivos |
|---|---|---|
| SSH | Solo clave pública, sin root, sin contraseña | `/etc/ssh/sshd_config.d/05-hardening.conf` |
| Firewall | nftables: entrada en `drop` y solo deja pasar lo de la lista de abajo | `/etc/nftables.conf` (respaldo `.pre-auditoria`) |
| Docker | Los puertos de los proyectos se publican solo en `127.0.0.1` | `docker-compose.yml` de SmartPack y aromas-del-norte; `/etc/docker/daemon.json` |
| Bloqueo | hypridle: atenúa a 2.5 min, bloquea a 5 min, apaga la pantalla a 5.5 min y **bloquea antes de suspender** | `~/.config/hypr/hypridle.conf` |
| Polkit | hyprpolkitagent: las ventanas de contraseña gráficas funcionan | servicio de usuario |

**Qué deja entrar el firewall:**
- loopback, conexiones ya establecidas, ICMP, DHCP y mDNS;
- **SSH solo desde 192.168.1.0/24;**
- syncthing (22000 y 21027);
- tráfico de los contenedores (`docker0`, `br-*`) y de libvirt hacia el host.

**Notas:**
- `nftables.service` es de tipo `oneshot`: que aparezca "inactive" después de cargar es normal. Si no carga, `systemctl show -p Result nftables` deja de decir `success`.
- Los puertos que publica Docker **no pasan** por la cadena `input`. Por eso se limitaron con `127.0.0.1:` en cada compose.
- `daemon.json` (`"ip": "127.0.0.1"`) solo afecta a la red `bridge` por defecto, no a las redes de compose.
- Fuera de tu red 192.168.1.x, SSH queda bloqueado a propósito.

### Mantenimiento automático
| Timer o servicio | Qué hace |
|---|---|
| `snapper-cleanup.timer` | Limpieza diaria de snapshots según los límites |
| `btrfs-scrub@-.timer` | Scrub mensual de btrfs para verificar la integridad de los datos |
| `smartd` | Vigila la salud del NVMe (avisa en el journal) |
| `paccache.timer` | Semanal: `paccache -rk2` (2 versiones) y `-ruk0` (nada de los desinstalados) |
| `rebuild-detector` | Hook de pacman: avisa qué paquetes de AUR hay que recompilar |
| `fwupd` | Firmware: `fwupdmgr get-updates` (solo consultar) |

**Firmware:** la BIOS F.21 no tiene actualización en LVFS. **No apliques la actualización de "UEFI dbx"**: Secure Boot está desactivado, así que no aporta nada, y con Windows en el mismo disco puede pedir la clave de BitLocker.

## 8. Paquetes que cambiaron en la auditoría

- **Instalados:**
  - de sistema: hypridle, hyprpolkitagent, dmidecode, fwupd, rebuild-detector;
  - usados por atajos: hyprpicker (SUPER+SHIFT+C), yazi (SUPER+SHIFT+E).
- **Desinstalados:**
  - postgresql: estaba registrado con 0 archivos por el incidente; sus datos se respaldaron en `~/Backups/auditoria/var-lib-postgres-*.tar.zst`;
  - huérfanos: electron42, llvm21, hyprwayland-scanner, python-pyaml;
  - legado: webkit2gtk 4.0, libsoup 2, openssl-1.1;
  - temas sin uso: catppuccin-gtk-latte, sddm-sugar-candy, candy-icons;
  - apps: zoom, onlyoffice, heroic, ryujinx, protonup-qt;
  - del rice: matugen-bin, hyprpaper;
  - gpsd, que solo usaba waybar 0.15.

  Al quitar hyprpaper también salió la pila gráfica de 32 bits (lib32-mesa, lib32-nvidia-utils y sus dependencias), que no usaba nada porque no hay Steam ni Wine. Si instalas Steam, vuelve sola.
- **Conservados a propósito:**
  - `gst-plugins-ugly`, que usan showtime, gnome-music y decibels;
  - `catppuccin-gtk-theme-mocha`, que aplican los temas del rice;
  - las herramientas de pentest.
- **`.pacnew`:** se resolvieron los 8. **Nunca** apliques `mkinitcpio.conf.pacnew` a ciegas: trae hooks de systemd y el hook `grub-btrfs-overlayfs` necesita `udev`.

## 9. Respaldos y archivos de referencia

| Ruta | Contenido |
|---|---|
| `~/Backups/hypr-backup-2026-11-03.tar.gz` | Rice antes de la migración |
| `~/Backups/btrfs-split/` | `split.sh` y `rehearse.sh` (P1), `p3/` (snapper, `snap-restore`, hook), `p5/` (pre/post de actualización) |
| `~/Backups/auditoria/` | Scripts `ab/`, `cd/`, `e/`, informes en `informes/`, tar de postgres y del rice |
| `/etc/*.pre-auditoria`, `*.pre-p3`, `*.pre-fase5`, `fstab.pre-split` | Respaldos de cada archivo de sistema modificado |

## 10. Comandos útiles

```bash
snapper -c root list                      # snapshots (sin sudo)
snapper -c root create -d "antes de X" -u important=yes
sudo snap-restore <N>                     # volver a un snapshot (luego reiniciar)
sudo btrfs filesystem usage /             # ver "Device unallocated"
journalctl -b -p err                      # errores del arranque actual
systemctl --failed                        # servicios caídos
sudo nft list ruleset                     # firewall
fwupdmgr get-updates                      # firmware disponible
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
~/.config/hypr/scripts/hypr-do.sh mode    # lua o legacy
```

## 11. Pendientes

- Borrar el snapshot 6 cuando Hyprland 0.57 lleve unos días estable.
- Volver de `waybar-git` a `waybar` (`sudo pacman -S waybar`) cuando la 0.16 esté en los repos oficiales; mientras tanto, `rebuild-detector` avisa si hay que recompilarlo.
- Los documentos viejos del repositorio (`README.md`, `QUICKSTART.md`, `AUDITORIA.md`, `DEPENDENCIES.md`, etc.) todavía describen matugen, swww y swaync.
- SmartPack (lo resuelve el usuario):
  - con `BUILD_DB=TRUE`, `project.seeder.ts`, que no tolera correr dos veces, hace que el contenedor se reinicie en bucle;
  - el compose mapea `5433:5433`, pero postgres escucha en el 5432.
