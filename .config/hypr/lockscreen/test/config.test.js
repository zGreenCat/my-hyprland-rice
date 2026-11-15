import System from 'system';

import { ConfigError, FailureTracker, LAYOUTS, clockParts, easeInOutCubic, parseThemeConfig, revealFrame } from '../config.js';

let failed = 0;
let passed = 0;

function test(name, fn) {
    try {
        fn();
        passed += 1;
        print(`ok   ${name}`);
    } catch (e) {
        failed += 1;
        printerr(`FAIL ${name}\n     ${e.message}`);
    }
}

function assertEqual(actual, expected, label = '') {
    const a = JSON.stringify(actual);
    const b = JSON.stringify(expected);
    if (a !== b)
        throw new Error(`${label} esperado ${b}, llegó ${a}`);
}

function assertThrows(fn, pattern) {
    try {
        fn();
    } catch (e) {
        if (!(e instanceof ConfigError))
            throw new Error(`lanzó ${e.name} en vez de ConfigError`);
        if (pattern && !pattern.test(e.message))
            throw new Error(`mensaje inesperado: ${e.message}`);
        return;
    }
    throw new Error('no lanzó error');
}

const validConfig = {
    theme: 'charigod',
    layout: 'orbital',
    video: '/home/u/.local/share/lockscreen/charigod.mp4',
    wallpaper: '/home/u/Pictures/w.jpg',
    colors: { fg: '#EBE1D8', accent: '#f7a253', red: '#e5677f', bg: '#14120f' },
};

test('parsea una configuración válida y normaliza colores', () => {
    const cfg = parseThemeConfig(JSON.stringify(validConfig));
    assertEqual(cfg.layout, 'orbital');
    assertEqual(cfg.colors.fg, '#ebe1d8');
    assertEqual(cfg.video, validConfig.video);
});

test('video y wallpaper vacíos quedan en null', () => {
    const cfg = parseThemeConfig(JSON.stringify({ ...validConfig, video: '', wallpaper: null }));
    assertEqual(cfg.video, null);
    assertEqual(cfg.wallpaper, null);
});

test('sin layout usa apilado', () => {
    const { layout, ...rest } = validConfig;
    assertEqual(parseThemeConfig(JSON.stringify(rest)).layout, 'apilado');
});

test('los cuatro diseños son válidos', () => {
    for (const layout of LAYOUTS)
        assertEqual(parseThemeConfig(JSON.stringify({ ...validConfig, layout })).layout, layout);
});

test('rechaza JSON inválido', () => assertThrows(() => parseThemeConfig('{no'), /JSON válido/));
test('rechaza un arreglo', () => assertThrows(() => parseThemeConfig('[]'), /objeto/));
test('rechaza un layout desconocido', () =>
    assertThrows(() => parseThemeConfig(JSON.stringify({ ...validConfig, layout: 'otro' })), /layout desconocido/));
test('rechaza un color mal formado', () =>
    assertThrows(() => parseThemeConfig(JSON.stringify({ ...validConfig, colors: { ...validConfig.colors, accent: 'naranja' } })), /colors\.accent/));
test('rechaza colores ausentes', () =>
    assertThrows(() => parseThemeConfig(JSON.stringify({ ...validConfig, colors: undefined })), /colors\.fg/));
test('rechaza una ruta de video relativa', () =>
    assertThrows(() => parseThemeConfig(JSON.stringify({ ...validConfig, video: 'videos/x.mp4' })), /ruta absoluta/));

test('los primeros intentos fallidos no bloquean', () => {
    const t = new FailureTracker({ freeAttempts: 3, baseDelayMs: 5000 });
    t.registerFailure(0); t.registerFailure(0); t.registerFailure(0);
    assertEqual(t.remainingMs(0), 0);
});

test('después de los intentos libres la espera se duplica hasta el tope', () => {
    const t = new FailureTracker({ freeAttempts: 1, baseDelayMs: 1000, maxDelayMs: 3000 });
    t.registerFailure(0);
    t.registerFailure(0);
    assertEqual(t.remainingMs(0), 1000, '2º fallo');
    t.registerFailure(0);
    assertEqual(t.remainingMs(0), 2000, '3º fallo');
    t.registerFailure(0);
    assertEqual(t.remainingMs(0), 3000, '4º fallo (tope)');
    assertEqual(t.remainingMs(2500), 500, 'descuenta el tiempo transcurrido');
});

test('un acierto reinicia el contador', () => {
    const t = new FailureTracker({ freeAttempts: 0, baseDelayMs: 1000 });
    t.registerFailure(0);
    t.registerSuccess();
    assertEqual([t.failures, t.remainingMs(0)], [0, 0]);
});

test('clockParts entrega hora, fecha en español y UTC', () => {
    const date = new Date(Date.UTC(2026, 10, 14, 21, 5));
    const parts = clockParts(date);
    assertEqual(parts.mm, '05');
    assertEqual(parts.utc, '21:05');
    assertEqual(parts.monthLong, 'noviembre');
    assertEqual(parts.dayNum, '14');
});

test('easeInOutCubic va de 0 a 1, simétrica y monótona', () => {
    assertEqual(easeInOutCubic(0), 0);
    assertEqual(easeInOutCubic(0.5), 0.5);
    assertEqual(easeInOutCubic(1), 1);
    assertEqual(Math.abs(easeInOutCubic(0.25) + easeInOutCubic(0.75) - 1) < 1e-12, true, 'simetría');
    let prev = -1;
    for (let i = 0; i <= 100; i++) {
        const v = easeInOutCubic(i / 100);
        if (v < prev)
            throw new Error(`no es monótona en t=${i / 100}`);
        prev = v;
    }
});

test('revealFrame: al inicio todo visible y video a velocidad normal', () => {
    assertEqual(revealFrame(0), { uiOpacity: 1, rootOpacity: 1, rate: 1, done: false });
});

test('revealFrame: el reloj se va antes que la ventana', () => {
    const f = revealFrame(1 / 3);
    assertEqual(f.uiOpacity, 0, 'ui');
    assertEqual(f.rootOpacity > 0.8, true, 'ventana aún casi opaca');
});

test('revealFrame: al final ventana transparente, video casi detenido y terminado', () => {
    assertEqual(revealFrame(1), { uiOpacity: 0, rootOpacity: 0, rate: 0.05, done: true });
    assertEqual(revealFrame(1.7), revealFrame(1), 't > 1 se recorta');
    assertEqual(revealFrame(-0.2), revealFrame(0), 't < 0 se recorta');
});

test('revealFrame sin xray deja la ventana opaca (no muestra negro)', () => {
    for (const t of [0, 0.5, 1])
        assertEqual(revealFrame(t, false).rootOpacity, 1, `t=${t}`);
});

print(`\n${passed} ok, ${failed} fallidos`);
System.exit(failed ? 1 : 0);
