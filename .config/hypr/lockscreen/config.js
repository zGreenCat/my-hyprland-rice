export const LAYOUTS = ['apilado', 'telemetria', 'orbital', 'horizonte'];

export const DEFAULT_CONFIG = Object.freeze({
    theme: 'default',
    layout: 'apilado',
    video: null,
    wallpaper: null,
    colors: Object.freeze({ fg: '#e6e9ee', accent: '#a7c080', red: '#e67e80', bg: '#11151a' }),
});

const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;

export class ConfigError extends Error {
    constructor(message) {
        super(message);
        this.name = 'ConfigError';
    }
}

function requireColor(colors, key) {
    const value = colors?.[key];
    if (typeof value !== 'string' || !HEX_COLOR.test(value))
        throw new ConfigError(`colors.${key} debe ser un color #rrggbb, llegó: ${JSON.stringify(value)}`);
    return value.toLowerCase();
}

function optionalPath(raw, key) {
    const value = raw[key];
    if (value === undefined || value === null || value === '')
        return null;
    if (typeof value !== 'string' || !value.startsWith('/'))
        throw new ConfigError(`${key} debe ser una ruta absoluta, llegó: ${JSON.stringify(value)}`);
    return value;
}

export function parseThemeConfig(text) {
    let raw;
    try {
        raw = JSON.parse(text);
    } catch (e) {
        throw new ConfigError(`theme.json no es JSON válido: ${e.message}`);
    }
    if (typeof raw !== 'object' || raw === null || Array.isArray(raw))
        throw new ConfigError('theme.json debe ser un objeto');

    const layout = raw.layout ?? DEFAULT_CONFIG.layout;
    if (!LAYOUTS.includes(layout))
        throw new ConfigError(`layout desconocido: ${JSON.stringify(layout)} (válidos: ${LAYOUTS.join(', ')})`);

    return {
        theme: typeof raw.theme === 'string' && raw.theme ? raw.theme : DEFAULT_CONFIG.theme,
        layout,
        video: optionalPath(raw, 'video'),
        wallpaper: optionalPath(raw, 'wallpaper'),
        colors: {
            fg: requireColor(raw.colors, 'fg'),
            accent: requireColor(raw.colors, 'accent'),
            red: requireColor(raw.colors, 'red'),
            bg: requireColor(raw.colors, 'bg'),
        },
    };
}

export class FailureTracker {
    constructor({ freeAttempts = 3, baseDelayMs = 5000, maxDelayMs = 60000 } = {}) {
        this.freeAttempts = freeAttempts;
        this.baseDelayMs = baseDelayMs;
        this.maxDelayMs = maxDelayMs;
        this.failures = 0;
        this.blockedUntil = 0;
    }

    registerFailure(nowMs) {
        this.failures += 1;
        const over = this.failures - this.freeAttempts;
        if (over > 0)
            this.blockedUntil = nowMs + Math.min(this.baseDelayMs * 2 ** (over - 1), this.maxDelayMs);
    }

    registerSuccess() {
        this.failures = 0;
        this.blockedUntil = 0;
    }

    remainingMs(nowMs) {
        return Math.max(0, this.blockedUntil - nowMs);
    }
}

export function clockParts(date, locale = 'es-CL') {
    const fmt = (options) => new Intl.DateTimeFormat(locale, options).format(date).replace('.', '');
    const pad = (n) => String(n).padStart(2, '0');
    return {
        hh: pad(date.getHours()),
        mm: pad(date.getMinutes()),
        utc: `${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}`,
        day: fmt({ weekday: 'long' }),
        dayShort: fmt({ weekday: 'short' }),
        dayNum: pad(date.getDate()),
        month: fmt({ month: 'short' }),
        monthLong: fmt({ month: 'long' }),
    };
}
