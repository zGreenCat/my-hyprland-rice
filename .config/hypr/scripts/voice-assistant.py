#!/usr/bin/env python3
"""
Asistente de voz: Handy STT → Claude Code → Piper TTS
Alt+Z press 1: abre ventana GTK, inicia grabación
Alt+Z press 2: para, lee SQLite, procesa, responde en voz, cierra
"""

import json
import os
import signal
import sqlite3
import threading
import subprocess
import time
from pathlib import Path

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

try:
    import anthropic as _anthropic_mod
    _ANTHROPIC_AVAILABLE = True
except ImportError:
    _ANTHROPIC_AVAILABLE = False

HANDY_DB = Path.home() / ".local/share/com.pais.handy/history.db"
PIPER_MODEL = Path.home() / ".local/share/piper/es_AR-daniela-high.onnx"
PID_FILE = Path("/tmp/voice-assistant.pid")
CLAUDE_BIN = Path.home() / ".local/bin/claude"
CLAUDE_CREDS = Path.home() / ".claude" / ".credentials.json"
PIPER_BIN = Path("/opt/piper-tts/piper")
HISTORY_FILE = Path.home() / ".local/share/voice-assistant/history.json"
PIPER_ENV = {
    **os.environ,
    "LD_LIBRARY_PATH": "/opt/piper-tts",
    "ESPEAK_DATA_PATH": "/opt/piper-tts/espeak-ng-data",
}

MAX_RECORDING_SECONDS = 30
TRANSCRIPTION_POLL_MS = 200   # intervalo de polling SQLite
TRANSCRIPTION_TIMEOUT_S = 15  # máximo a esperar transcripción

SYSTEM_PROMPT = """Eres un asistente de voz personal en Arch Linux con Hyprland. Reglas estrictas:
- Responde SIEMPRE en español
- Máximo 2 oraciones cortas — tu respuesta se leerá en voz alta con TTS
- Sin markdown, sin listas, solo texto plano conversacional
- Usa la herramienta bash cuando el usuario pida abrir apps, controlar música, ajustar volumen, etc.
- Para abrir apps usa: ~/.config/hypr/scripts/hypr-do.sh exec <app>
- Para Spotify: 'spotify' abre el cliente, 'playerctl -p spotify <play|pause|next|previous>' controla reproducción
- Para buscar y reproducir en Spotify: playerctl -p spotify open 'spotify:search:<query>'"""

BASH_TOOL = {
    "name": "bash",
    "description": "Ejecuta un comando bash en el sistema del usuario. Úsalo para abrir apps, controlar Spotify/música, ajustar volumen, configuración, etc.",
    "input_schema": {
        "type": "object",
        "properties": {
            "command": {"type": "string", "description": "Comando bash a ejecutar"}
        },
        "required": ["command"],
    },
}

ACTIVE_FILE = Path.home() / ".config/hypr/.active-theme"
THEMES_DIR  = Path.home() / ".config/hypr/themes"
_DEFAULTS   = {
    "C_BG": "#0a0a14", "C_CRUST": "#050508", "C_SURFACE0": "#1a1a2e",
    "C_ACCENT": "#aa00ff", "C_FG": "#e0e0ff", "C_FG2": "#a0a0c0",
    "COLOR_SCHEME": "dark", "HYPR_ROUNDING": "12",
}

def _rgb(h: str):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def _rgba(h: str, a: float) -> str:
    r, g, b = _rgb(h)
    return f"rgba({r},{g},{b},{a})"

def _load_conf(path: Path) -> dict:
    out = {}
    try:
        for line in path.read_text().splitlines():
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip().strip('"')
    except Exception:
        pass
    return out

def _active_colors() -> dict:
    active = ""
    try: active = ACTIVE_FILE.read_text().strip()
    except Exception: pass
    c = {**_DEFAULTS}
    p = THEMES_DIR / active / "theme.conf"
    if active and p.exists():
        c.update(_load_conf(p))
    return c

def _build_css(c: dict) -> bytes:
    is_light = c.get("COLOR_SCHEME") == "light"
    bg      = c.get("C_CRUST",   _DEFAULTS["C_CRUST"])
    accent  = c.get("C_ACCENT",  _DEFAULTS["C_ACCENT"])
    fg      = c.get("C_FG",      _DEFAULTS["C_FG"])
    fg2     = c.get("C_FG2",     _DEFAULTS["C_FG2"])
    surf    = c.get("C_SURFACE0",_DEFAULTS["C_SURFACE0"])
    rounding = c.get("HYPR_ROUNDING", "12")
    if is_light:
        bg, fg, fg2, surf = fg, bg, c.get("C_OVERLAY","#606080"), c.get("C_MANTLE","#e0e0e0")
    return f"""
window {{
    background: {_rgba(bg, 0.97)};
    border-radius: {rounding}px;
    border: 1px solid {_rgba(accent, 0.4)};
}}
label.status {{
    color: {_rgba(fg2, 0.75)};
    font-size: 13px;
}}
entry {{
    background: {_rgba(surf, 0.8)};
    color: {_rgba(fg, 0.9)};
    border: 1px solid {_rgba(accent, 0.5)};
    border-radius: {min(int(rounding), 8)}px;
    padding: 8px;
    font-size: 14px;
}}
entry:focus {{
    border-color: {_rgba(accent, 0.9)};
    box-shadow: none;
}}
label.response {{
    color: {_rgba(fg, 0.88)};
    font-size: 13px;
}}
label.badge {{
    color: {_rgba(accent, 0.7)};
    font-size: 11px;
}}
""".encode()


def get_transcription_count() -> int:
    if not HANDY_DB.exists():
        return 0
    conn = sqlite3.connect(str(HANDY_DB))
    count = conn.execute("SELECT COUNT(*) FROM transcription_history").fetchone()[0]
    conn.close()
    return count


def get_latest_transcription() -> str | None:
    if not HANDY_DB.exists():
        return None
    conn = sqlite3.connect(str(HANDY_DB))
    row = conn.execute(
        "SELECT transcription_text FROM transcription_history ORDER BY timestamp DESC LIMIT 1"
    ).fetchone()
    conn.close()
    return row[0] if row else None


def load_history() -> list[dict]:
    if HISTORY_FILE.exists():
        try:
            return json.loads(HISTORY_FILE.read_text())
        except (json.JSONDecodeError, OSError):
            return []
    return []


def save_history(history: list[dict]) -> None:
    HISTORY_FILE.parent.mkdir(parents=True, exist_ok=True)
    HISTORY_FILE.write_text(json.dumps(history[-20:], ensure_ascii=False, indent=2))


def speak(text: str) -> None:
    if not PIPER_MODEL.exists():
        return
    wav_file = Path("/tmp/voice-assistant-tts.wav")
    try:
        subprocess.run(
            [str(PIPER_BIN), "--model", str(PIPER_MODEL),
             "--espeak_data", "/opt/piper-tts/espeak-ng-data", "-f", str(wav_file)],
            input=text.encode(),
            capture_output=True,
            env=PIPER_ENV,
        )
        subprocess.run(["paplay", str(wav_file)], capture_output=True)
    except FileNotFoundError:
        pass
    finally:
        wav_file.unlink(missing_ok=True)


def _load_oauth_token() -> str | None:
    try:
        creds = json.loads(CLAUDE_CREDS.read_text())
        return creds["claudeAiOauth"]["accessToken"]
    except Exception:
        return None


def build_messages(text: str, history: list[dict]) -> list[dict]:
    msgs = []
    for h in history[-4:]:
        msgs.append({"role": "user", "content": h["user"]})
        msgs.append({"role": "assistant", "content": h["assistant"]})
    msgs.append({"role": "user", "content": text})
    return msgs



class VoiceAssistantWindow(Gtk.Window):
    def __init__(self) -> None:
        super().__init__(title="Asistente de Voz")
        self.set_default_size(520, 300)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_resizable(False)

        screen = Gdk.Screen.get_default()
        if v := screen.get_rgba_visual():
            self.set_visual(v)
        self.set_app_paintable(True)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(_build_css(_active_colors()))
        Gtk.StyleContext.add_provider_for_screen(
            screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        box.set_margin_top(14)
        box.set_margin_bottom(14)
        box.set_margin_start(18)
        box.set_margin_end(18)
        self.add(box)

        self.status_label = Gtk.Label(label="🎤 Escuchando... habla ahora")
        self.status_label.get_style_context().add_class("status")
        self.status_label.set_halign(Gtk.Align.START)
        self.status_label.set_line_wrap(True)
        box.pack_start(self.status_label, False, False, 0)

        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text("Texto transcrito aparece aquí...")
        box.pack_start(self.entry, False, False, 0)

        self.response_label = Gtk.Label(label="")
        self.response_label.get_style_context().add_class("response")
        self.response_label.set_halign(Gtk.Align.START)
        self.response_label.set_line_wrap(True)
        self.response_label.set_max_width_chars(62)
        box.pack_start(self.response_label, True, True, 0)

        self.badge_label = Gtk.Label(label="")
        self.badge_label.get_style_context().add_class("badge")
        self.badge_label.set_halign(Gtk.Align.END)
        box.pack_end(self.badge_label, False, False, 0)

        self.history = load_history()
        self._timeout_id: int | None = None
        self._count_before: int = 0
        self._poll_deadline: float = 0

    def start_recording(self) -> None:
        self._count_before = get_transcription_count()
        subprocess.run(["handy", "--toggle-transcription"])
        self.present()
        self.entry.grab_focus()
        # Forzar foco a nivel compositor (Handy inyecta via wtype, necesita foco Wayland)
        subprocess.run(
            ["hyprctl", "dispatch", "focuswindow", "title:Asistente de Voz"],
            capture_output=True,
        )
        self._timeout_id = GLib.timeout_add_seconds(MAX_RECORDING_SECONDS, self._on_timeout)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, self._on_stop_signal)

    def _on_timeout(self) -> bool:
        self.status_label.set_text("⏱️ Tiempo máximo alcanzado")
        # Detener grabación y esperar transcripción final
        subprocess.run(["handy", "--toggle-transcription"])
        self.status_label.set_text("🤔 Procesando...")
        self._poll_deadline = time.time() + TRANSCRIPTION_TIMEOUT_S
        GLib.timeout_add(TRANSCRIPTION_POLL_MS, self._poll_transcription)
        return False

    def _on_stop_signal(self) -> bool:
        if self._timeout_id is not None:
            GLib.source_remove(self._timeout_id)
            self._timeout_id = None
        subprocess.run(["handy", "--toggle-transcription"])  # detiene grabación → dispara procesamiento
        self.status_label.set_text("🤔 Procesando...")
        self._poll_deadline = time.time() + TRANSCRIPTION_TIMEOUT_S
        GLib.timeout_add(TRANSCRIPTION_POLL_MS, self._poll_transcription)
        return True

    def _poll_transcription(self) -> bool:
        if get_transcription_count() > self._count_before:
            text = get_latest_transcription() or ""
            if text:
                self.entry.set_text(text)
                self.entry.set_sensitive(False)
                threading.Thread(target=self._run_llm, args=(text,), daemon=True).start()
                return False

        if time.time() > self._poll_deadline:
            text = self.entry.get_text().strip()
            if text:
                self.entry.set_sensitive(False)
                threading.Thread(target=self._run_llm, args=(text,), daemon=True).start()
            else:
                self.status_label.set_text("⚠️ Sin texto detectado")
                GLib.timeout_add_seconds(2, Gtk.main_quit)
            return False

        return True

    def _run_llm(self, text: str) -> None:
        response = ""
        model = "none"
        messages = build_messages(text, self.history)

        GLib.idle_add(self._set_status, "🔄 Respondiendo...")

        # Ruta primaria: SDK directo con tool use (~1s, soporta bash)
        if _ANTHROPIC_AVAILABLE:
            token = _load_oauth_token()
            if token:
                try:
                    client = _anthropic_mod.Anthropic(api_key=token)

                    for _ in range(5):  # máx 5 turnos de herramientas
                        resp = client.messages.create(
                            model="claude-haiku-4-5",
                            max_tokens=300,
                            system=SYSTEM_PROMPT,
                            messages=messages,
                            tools=[BASH_TOOL],
                        )

                        for block in resp.content:
                            if block.type == "text" and block.text.strip():
                                response = block.text
                                GLib.idle_add(self._update_response_label, response.strip())

                        if resp.stop_reason != "tool_use":
                            model = "claude-sdk"
                            break

                        # Ejecutar herramientas bash
                        messages.append({"role": "assistant", "content": resp.content})
                        tool_results = []
                        for block in resp.content:
                            if block.type == "tool_use":
                                cmd = block.input.get("command", "")
                                GLib.idle_add(self._set_status, f"🔧 Ejecutando...")
                                try:
                                    result = subprocess.run(
                                        cmd, shell=True, capture_output=True,
                                        text=True, timeout=15,
                                    )
                                    output = (result.stdout + result.stderr).strip() or "ok"
                                except Exception as e:
                                    output = str(e)
                                tool_results.append({
                                    "type": "tool_result",
                                    "tool_use_id": block.id,
                                    "content": output[:500],
                                })
                        messages.append({"role": "user", "content": tool_results})
                        GLib.idle_add(self._set_status, "🔄 Respondiendo...")

                except Exception:
                    response = ""

        # Fallback: CLI (más lento, ~6s)
        if not response.strip():
            try:
                proc = subprocess.Popen(
                    [str(CLAUDE_BIN), "-p", "--allowedTools", "Bash", "--model", "claude-haiku-4-5"],
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, text=True,
                )
                assert proc.stdin and proc.stdout
                proc.stdin.write(SYSTEM_PROMPT + f"\n\nUsuario: {text}")
                proc.stdin.close()
                for chunk in proc.stdout:
                    response += chunk
                    GLib.idle_add(self._update_response_label, response.strip())
                proc.wait(timeout=30)
                if proc.returncode == 0 and response.strip():
                    model = "claude-cli"
            except (FileNotFoundError, subprocess.TimeoutExpired):
                pass

        final = response.strip() or "No pude conectar con ningún modelo de lenguaje."
        self.history.append({"user": text, "assistant": final})
        save_history(self.history)
        GLib.idle_add(self._finalize_response, final, model)

    def _set_status(self, text: str) -> bool:
        self.status_label.set_text(text)
        return False

    def _update_response_label(self, text: str) -> bool:
        self.response_label.set_text(text)
        return False

    def _finalize_response(self, response: str, model: str) -> bool:
        self.status_label.set_text("🔊 Hablando...")
        self.response_label.set_text(response)
        self.badge_label.set_text(f"[{model}]")
        threading.Thread(target=self._speak_and_close, args=(response,), daemon=True).start()
        return False

    def _speak_and_close(self, response: str) -> None:
        speak(response)
        GLib.idle_add(Gtk.main_quit)


def main() -> None:
    if PID_FILE.exists():
        try:
            pid = int(PID_FILE.read_text().strip())
            os.kill(pid, signal.SIGUSR1)
        except (ProcessLookupError, ValueError):
            PID_FILE.unlink(missing_ok=True)
        else:
            return

    PID_FILE.write_text(str(os.getpid()))
    try:
        win = VoiceAssistantWindow()
        win.connect("destroy", lambda _: Gtk.main_quit())
        win.show_all()
        win.start_recording()
        Gtk.main()
    finally:
        PID_FILE.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
