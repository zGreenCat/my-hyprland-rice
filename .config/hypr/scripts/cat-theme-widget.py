#!/usr/bin/env python3
"""
════════════════════════════════════════════════════════════════════════
 🐈 Cat Theme Toggle Widget - Gatitos CSS enfrentados con slider
 Toggle visual HTML/CSS con mini-gatos adaptados del diseño CSS original
════════════════════════════════════════════════════════════════════════
"""

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk, Gdk, GLib, WebKit2
import subprocess
import os

THEME_FILE = os.path.expanduser("~/.config/hypr/.theme-mode")
THEME_SCRIPT = os.path.expanduser("~/.config/hypr/scripts/cat-theme-toggle.sh")
HTML_FILE = os.path.expanduser("~/.config/hypr/scripts/cat-theme-toggle.html")

AUTO_CLOSE_DELAY = 2000  # Milisegundos antes de cerrar (2 segundos)

class CatThemeToggle(Gtk.Window):
    def __init__(self):
        super().__init__()
        
        # Configuración de ventana
        self.set_title("Cat Theme Toggle")
        self.set_default_size(200, 120)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_app_paintable(True)
        
        # Hacer ventana transparente
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        
        # Estado
        self.is_light = self.load_theme()
        
        # 🔄 Toggle automático al abrir
        self.is_light = not self.is_light
        new_theme = 'light' if self.is_light else 'dark'
        
        # Aplicar tema inmediatamente (en background)
        self.apply_theme_async()
        
        # WebView para mostrar HTML
        self.webview = WebKit2.WebView()
        self.webview.set_background_color(Gdk.RGBA(0, 0, 0, 0))
        
        # Cargar HTML con parámetro de tema
        html_uri = f"file://{HTML_FILE}?theme={new_theme}"
        self.webview.load_uri(html_uri)
        
        self.add(self.webview)
        
        # Auto-cerrar después de la animación
        GLib.timeout_add(AUTO_CLOSE_DELAY, self.auto_close)
        
        self.show_all()
    
    def load_theme(self):
        """Cargar tema actual desde archivo"""
        try:
            with open(THEME_FILE, 'r') as f:
                return f.read().strip() == 'light'
        except:
            return False  # Default dark
    
    def apply_theme_async(self):
        """Ejecutar script de cambio de tema en background"""
        subprocess.Popen(
            ['bash', THEME_SCRIPT],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    
    def auto_close(self):
        """Cerrar ventana automáticamente"""
        self.destroy()
        return False

if __name__ == '__main__':
    # Verificar que el archivo HTML existe
    if not os.path.exists(HTML_FILE):
        print(f"❌ Error: No se encuentra {HTML_FILE}")
        print("   Asegúrate de que cat-theme-toggle.html esté en ~/.config/hypr/scripts/")
        exit(1)
    
    win = CatThemeToggle()
    win.connect('destroy', Gtk.main_quit)
    Gtk.main()
