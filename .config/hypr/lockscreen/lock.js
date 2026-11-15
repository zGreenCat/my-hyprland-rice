import Gdk from 'gi://Gdk?version=4.0';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Gst from 'gi://Gst?version=1.0';
import Gtk from 'gi://Gtk?version=4.0';
import SessionLock from 'gi://Gtk4SessionLock';
import System from 'system';

import { DEFAULT_CONFIG, FailureTracker, clockParts, parseThemeConfig, revealFrame } from './config.js';

const DIR = GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]);
const CONFIG_PATH = GLib.build_filenamev([DIR, 'theme.json']);
const STYLE_PATH = GLib.build_filenamev([DIR, 'style.css']);
const AUTH_HELPER = GLib.build_filenamev([DIR, 'auth.py']);
const TEST_UNLOCK_AFTER = Number(GLib.getenv('LOCK_TEST_UNLOCK_AFTER') ?? 0);

const EXIT_FAILED_TO_LOCK = 3;
const ERROR_VISIBLE_MS = 2500;
const REVEAL_MS = 1100;
const REVEAL_SAFETY_MS = 3000;
const DECEL_STEPS = 12;
const DPMS_POLL_S = 5;

const log = (msg) => printerr(`[lockscreen] ${msg}`);

function loadConfig() {
    try {
        const [, bytes] = GLib.file_get_contents(CONFIG_PATH);
        return parseThemeConfig(new TextDecoder().decode(bytes));
    } catch (e) {
        log(`no se pudo cargar ${CONFIG_PATH}, uso valores por defecto: ${e.message}`);
        return DEFAULT_CONFIG;
    }
}

function loadCss(config) {
    const display = Gdk.Display.get_default();
    const colors = new Gtk.CssProvider();
    colors.load_from_string(Object.entries(config.colors)
        .map(([name, value]) => `@define-color lock_${name} ${value};`).join('\n'));
    Gtk.StyleContext.add_provider_for_display(display, colors, Gtk.STYLE_PROVIDER_PRIORITY_USER);

    const style = new Gtk.CssProvider();
    style.connect('parsing-error', (_p, section, error) =>
        log(`style.css ${section.to_string()}: ${error.message}`));
    style.load_from_path(STYLE_PATH);
    Gtk.StyleContext.add_provider_for_display(display, style, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1);
}

function runAsync(argv, input = null) {
    return new Promise((resolve, reject) => {
        let proc;
        try {
            const flags = Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
                | (input === null ? 0 : Gio.SubprocessFlags.STDIN_PIPE);
            proc = Gio.Subprocess.new(argv, flags);
        } catch (e) {
            reject(e);
            return;
        }
        proc.communicate_utf8_async(input, null, (p, res) => {
            try {
                const [, stdout, stderr] = p.communicate_utf8_finish(res);
                if (!p.get_if_exited()) {
                    reject(new Error(`${argv[0]} terminó por una señal`));
                    return;
                }
                resolve({ code: p.get_exit_status(), stdout: stdout ?? '', stderr: stderr ?? '' });
            } catch (e) {
                reject(e);
            }
        });
    });
}

// Con xray Hyprland dibuja el escritorio bajo el bloqueo: solo se activa tras autenticar.
async function setLockXray(enabled) {
    const { code, stdout, stderr } = await runAsync(
        ['hyprctl', 'eval', `hl.config({ misc = { session_lock_xray = ${enabled} } })`]);
    if (code !== 0 || stdout.trim() !== 'ok')
        throw new Error(`hyprctl eval respondió "${(stdout || stderr).trim()}"`);
}

async function authenticate(password) {
    const { code, stderr } = await runAsync(['python3', '-I', AUTH_HELPER], `${password}\n`);
    if (code === 0)
        return true;
    if (code === 1) {
        log(stderr.trim());
        return false;
    }
    throw new Error(`auth.py salió con código ${code}: ${stderr.trim()}`);
}

class Background {
    constructor(config) {
        this.config = config;
        this.playbin = null;
        this.paintable = null;
        this.rate = 1.0;
        this.looping = false;

        const video = config.video;
        if (video && GLib.file_test(video, GLib.FileTest.EXISTS))
            this.setupVideo(video);
        else if (video)
            log(`no existe el video ${video}, uso el wallpaper`);
    }

    setupVideo(path) {
        const sink = Gst.ElementFactory.make('gtk4paintablesink', 'sink');
        const playbin = Gst.ElementFactory.make('playbin', 'player');
        if (!sink || !playbin) {
            log('faltan gtk4paintablesink o playbin, uso el wallpaper');
            return;
        }
        playbin.set_property('uri', Gst.filename_to_uri(path));
        playbin.set_property('video-sink', sink);
        playbin.set_property('mute', true);

        const bus = playbin.get_bus();
        bus.add_signal_watch();
        bus.connect('message::async-done', () => {
            if (this.looping)
                return;
            this.looping = true;
            this.seekLoop(Gst.SeekFlags.FLUSH);
        });
        bus.connect('message::segment-done', () => this.seekLoop(0));
        bus.connect('message::eos', () => this.seekLoop(Gst.SeekFlags.FLUSH));
        bus.connect('message::error', (_bus, msg) => {
            const [err] = msg.parse_error();
            log(`error de video, sigue bloqueado sin video: ${err.message}`);
            playbin.set_state(Gst.State.NULL);
        });

        this.playbin = playbin;
        this.paintable = sink.paintable;
    }

    seekLoop(extraFlags) {
        this.playbin?.seek(this.rate, Gst.Format.TIME, Gst.SeekFlags.SEGMENT | extraFlags,
            Gst.SeekType.SET, 0, Gst.SeekType.NONE, -1);
    }

    createWidget() {
        if (this.paintable)
            return new Gtk.Picture({ paintable: this.paintable, content_fit: Gtk.ContentFit.COVER });
        const wallpaper = this.config.wallpaper;
        if (wallpaper && GLib.file_test(wallpaper, GLib.FileTest.EXISTS))
            return Gtk.Picture.new_for_filename(wallpaper);
        return new Gtk.Box();
    }

    play() {
        this.playbin?.set_state(Gst.State.PLAYING);
    }

    setPaused(paused) {
        this.playbin?.set_state(paused ? Gst.State.PAUSED : Gst.State.PLAYING);
    }

    setRate(rate) {
        if (!this.playbin)
            return false;
        this.rate = rate;
        return this.playbin.seek(rate, Gst.Format.TIME, Gst.SeekFlags.INSTANT_RATE_CHANGE,
            Gst.SeekType.NONE, -1, Gst.SeekType.NONE, -1);
    }

    stop() {
        this.playbin?.set_state(Gst.State.NULL);
    }
}

class AuthField {
    constructor(layout, onSubmit) {
        this.state = 'idle';
        this.root = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 });
        this.root.add_css_class('auth');

        this.field = new Gtk.Box({ spacing: 10, halign: Gtk.Align.FILL });
        this.field.add_css_class('field');
        if (layout === 'telemetria') {
            const prompt = new Gtk.Label({ label: '▸' });
            prompt.add_css_class('prompt');
            this.field.append(prompt);
        }
        this.entry = new Gtk.PasswordEntry({ show_peek_icon: false, hexpand: true, width_chars: 14 });
        this.entry.add_css_class('lock-entry');
        this.entry.connect('activate', () => onSubmit(this.entry.get_text()));
        this.entry.connect('changed', () => this.refresh());
        this.field.append(this.entry);

        this.msg = new Gtk.Label({ label: '' });
        this.msg.add_css_class('msg');
        this.root.append(this.field);
        this.root.append(this.msg);
    }

    setState(state, message = '') {
        for (const cls of ['verifying', 'error', 'blocked'])
            this.root.remove_css_class(cls);
        if (state !== 'idle')
            this.root.add_css_class(state);
        this.state = state;
        this.msg.set_label(message);
        this.entry.set_sensitive(state !== 'verifying' && state !== 'blocked');
        if (this.entry.get_sensitive())
            this.entry.grab_focus();
        this.refresh();
    }

    clear() {
        this.entry.set_text('');
    }

    refresh() {
        const shown = this.entry.get_text().length > 0 || this.state !== 'idle';
        if (shown)
            this.root.add_css_class('shown');
        else
            this.root.remove_css_class('shown');
    }
}

function label(cls, extra = {}) {
    const l = new Gtk.Label({ ...extra });
    for (const c of cls.split(' '))
        l.add_css_class(c);
    return l;
}

const LAYOUTS = {
    apilado(auth) {
        const hh = label('digits text-shadow');
        const mm = label('digits text-shadow');
        const date = label('date');
        const center = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER });
        [hh, mm, date].forEach((w) => center.append(w));
        auth.root.set_halign(Gtk.Align.CENTER);
        auth.root.set_valign(Gtk.Align.END);
        auth.root.set_margin_bottom(96);
        auth.msg.set_halign(Gtk.Align.CENTER);
        return {
            widgets: [center, auth.root],
            update(p) {
                hh.set_label(p.hh);
                mm.set_label(p.mm);
                date.set_label(`${p.day} ${Number(p.dayNum)}`);
            },
        };
    },

    telemetria(auth) {
        const time = label('time text-shadow', { halign: Gtk.Align.START });
        const sub = label('sub', { halign: Gtk.Align.START });
        const corner = new Gtk.Box({
            orientation: Gtk.Orientation.VERTICAL, spacing: 6,
            halign: Gtk.Align.START, valign: Gtk.Align.START, margin_top: 65, margin_start: 69,
        });
        corner.append(time);
        corner.append(sub);
        auth.root.set_halign(Gtk.Align.END);
        auth.root.set_valign(Gtk.Align.END);
        auth.root.set_margin_end(69);
        auth.root.set_margin_bottom(52);
        auth.msg.set_halign(Gtk.Align.END);
        return {
            widgets: [corner, auth.root],
            update(p) {
                time.set_label(`${p.hh}:${p.mm}`);
                sub.set_label(`${p.dayShort} ${p.dayNum} ${p.month} · utc ${p.utc}`.toUpperCase());
            },
        };
    },

    orbital(auth) {
        const time = label('time text-shadow', { halign: Gtk.Align.START });
        const date = label('date', { halign: Gtk.Align.START });
        const clock = new Gtk.Box({
            orientation: Gtk.Orientation.VERTICAL,
            halign: Gtk.Align.START, valign: Gtk.Align.END, margin_start: 77, margin_bottom: 84,
        });
        clock.append(time);
        clock.append(date);
        auth.root.set_halign(Gtk.Align.END);
        auth.root.set_valign(Gtk.Align.END);
        auth.root.set_margin_end(77);
        auth.root.set_margin_bottom(72);
        auth.msg.set_halign(Gtk.Align.END);
        return {
            widgets: [clock, auth.root],
            update(p) {
                time.set_label(`${p.hh}:${p.mm}`);
                date.set_label(`${p.dayShort} ${p.dayNum}`.toUpperCase());
            },
        };
    },

    horizonte(auth) {
        const time = label('time text-shadow');
        const date = label('date');
        const center = new Gtk.Box({
            orientation: Gtk.Orientation.VERTICAL, spacing: 17,
            halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER,
        });
        auth.root.set_halign(Gtk.Align.CENTER);
        auth.msg.set_halign(Gtk.Align.CENTER);
        [time, date, auth.root].forEach((w) => center.append(w));
        return {
            widgets: [center],
            update(p) {
                time.set_label(`${p.hh}:${p.mm}`);
                date.set_label(`${p.day} ${Number(p.dayNum)} ${p.monthLong}`.toUpperCase());
            },
        };
    },
};

function main() {
    Gst.init(null);
    Gtk.init();

    if (!SessionLock.is_supported()) {
        log('el compositor no soporta ext-session-lock');
        return EXIT_FAILED_TO_LOCK;
    }

    const config = loadConfig();
    loadCss(config);

    const background = new Background(config);
    const tracker = new FailureTracker();
    const lock = new SessionLock.Instance();
    const loop = new GLib.MainLoop(null, false);
    const screens = [];
    let exitCode = 0;
    let busy = false;
    let unlocking = false;
    let errorTimer = 0;

    const setAll = (state, message = '') => screens.forEach((s) => s.auth.setState(state, message));
    const clearAll = () => screens.forEach((s) => s.auth.clear());

    const tick = () => {
        const parts = clockParts(new Date());
        screens.forEach((s) => s.layout.update(parts));
        const wait = tracker.remainingMs(Date.now());
        if (wait > 0)
            setAll('blocked', `demasiados intentos · espera ${Math.ceil(wait / 1000)} s`);
        else if (screens[0]?.auth.state === 'blocked')
            setAll('idle');
    };

    const unlockGracefully = async () => {
        if (unlocking)
            return;
        unlocking = true;

        let reveal = true;
        try {
            await setLockXray(true);
        } catch (e) {
            log(`no se pudo activar session_lock_xray, desbloqueo sin fundido al escritorio: ${e.message}`);
            reveal = false;
        }
        if (reveal)
            screens.forEach((s) => s.win.add_css_class('revealing'));

        let finished = false;
        let rateOk = true;
        let lastStep = 0;
        const finish = () => {
            if (finished)
                return;
            finished = true;
            background.stop();
            lock.unlock();
        };
        const safety = GLib.timeout_add(GLib.PRIORITY_DEFAULT, REVEAL_SAFETY_MS, () => {
            log('el fundido no terminó a tiempo; desbloqueo directo');
            finish();
            return GLib.SOURCE_REMOVE;
        });

        let start = 0;
        screens[0].root.add_tick_callback((_w, clock) => {
            const now = clock.get_frame_time() / 1000;
            start ||= now;
            const t = (now - start) / REVEAL_MS;
            const frame = revealFrame(t, reveal);
            screens.forEach((s) => {
                s.layout.widgets.forEach((w) => w.set_opacity(frame.uiOpacity));
                s.root.set_opacity(frame.rootOpacity);
            });
            const step = Math.floor(Math.min(1, t) * DECEL_STEPS);
            if (rateOk && step !== lastStep) {
                lastStep = step;
                rateOk = background.setRate(frame.rate);
            }
            if (!frame.done)
                return GLib.SOURCE_CONTINUE;
            GLib.source_remove(safety);
            finish();
            return GLib.SOURCE_REMOVE;
        });
    };

    const submit = async (password) => {
        if (busy || unlocking || !password)
            return;
        if (tracker.remainingMs(Date.now()) > 0)
            return;
        busy = true;
        if (errorTimer) {
            GLib.source_remove(errorTimer);
            errorTimer = 0;
        }
        setAll('verifying', 'verificando');
        try {
            const ok = await authenticate(password);
            if (ok) {
                tracker.registerSuccess();
                unlockGracefully();
                return;
            }
            tracker.registerFailure(Date.now());
            clearAll();
            setAll('error', 'contraseña incorrecta');
        } catch (e) {
            log(`no se pudo verificar la contraseña: ${e.message}`);
            clearAll();
            setAll('error', 'no se pudo verificar');
        } finally {
            busy = false;
        }
        errorTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ERROR_VISIBLE_MS, () => {
            errorTimer = 0;
            if (screens[0]?.auth.state === 'error')
                setAll('idle');
            tick();
            return GLib.SOURCE_REMOVE;
        });
    };

    lock.connect('monitor', (_lock, monitor) => {
        const auth = new AuthField(config.layout, submit);
        const layout = LAYOUTS[config.layout](auth);

        const overlay = new Gtk.Overlay();
        overlay.set_child(background.createWidget());
        const scrim = new Gtk.Box({ hexpand: true, vexpand: true, can_target: false });
        scrim.add_css_class(`scrim-${config.layout}`);
        overlay.add_overlay(scrim);
        const ui = new Gtk.Overlay({ hexpand: true, vexpand: true });
        ui.add_css_class(config.layout);
        ui.set_child(new Gtk.Box());
        layout.widgets.forEach((w) => ui.add_overlay(w));
        overlay.add_overlay(ui);

        const win = new Gtk.Window({ child: overlay });
        win.add_css_class('lockscreen');
        const keys = new Gtk.EventControllerKey({ propagation_phase: Gtk.PropagationPhase.CAPTURE });
        keys.connect('key-pressed', (_c, keyval) => {
            if (keyval !== Gdk.KEY_Escape)
                return false;
            auth.clear();
            if (auth.state === 'error')
                setAll('idle');
            return true;
        });
        win.add_controller(keys);
        win.connect('map', () => auth.entry.grab_focus());

        screens.push({ auth, layout, win, root: overlay });
        layout.update(clockParts(new Date()));
        lock.assign_window_to_monitor(win, monitor);
    });

    lock.connect('locked', () => {
        log(`bloqueado · tema ${config.theme} · diseño ${config.layout} · video ${background.paintable ? 'sí' : 'no'}`);
        background.play();
        if (TEST_UNLOCK_AFTER > 0) {
            log(`MODO PRUEBA: desbloqueo automático en ${TEST_UNLOCK_AFTER} s`);
            GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, TEST_UNLOCK_AFTER, () => {
                unlockGracefully();
                return GLib.SOURCE_REMOVE;
            });
        }
    });
    lock.connect('failed', () => {
        log('el compositor rechazó el bloqueo');
        exitCode = EXIT_FAILED_TO_LOCK;
        loop.quit();
    });
    lock.connect('unlocked', () => {
        log('desbloqueado');
        setLockXray(false)
            .catch((e) => log(`no se pudo desactivar session_lock_xray: ${e.message}`))
            .finally(() => loop.quit());
    });

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000 - (Date.now() % 1000), () => {
        tick();
        GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            tick();
            return GLib.SOURCE_CONTINUE;
        });
        return GLib.SOURCE_REMOVE;
    });

    if (background.playbin) {
        let screensOff = false;
        GLib.timeout_add_seconds(GLib.PRIORITY_LOW, DPMS_POLL_S, () => {
            runAsync(['hyprctl', '-j', 'monitors']).then(({ code, stdout }) => {
                if (code !== 0 || unlocking)
                    return;
                const off = JSON.parse(stdout).every((m) => m.dpmsStatus === false);
                if (off !== screensOff) {
                    screensOff = off;
                    background.setPaused(off);
                }
            }).catch((e) => log(`no se pudo consultar el estado de las pantallas: ${e.message}`));
            return GLib.SOURCE_CONTINUE;
        });
    }

    setLockXray(false).catch((e) => log(`no se pudo asegurar session_lock_xray apagado: ${e.message}`));
    if (!lock.lock()) {
        log('lock() devolvió false');
        return EXIT_FAILED_TO_LOCK;
    }
    loop.run();
    return exitCode;
}

System.exit(main());
