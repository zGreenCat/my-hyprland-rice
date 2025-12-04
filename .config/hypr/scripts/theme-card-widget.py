#!/usr/bin/env python3
"""
════════════════════════════════════════════════════════════════════════
 🌓 Theme Card Widget - Toggle visual animado con GTK + Cairo
 Tarjeta 3D flip con escenas de día/noche
════════════════════════════════════════════════════════════════════════
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import cairo
import math
import subprocess
import os

THEME_FILE = os.path.expanduser("~/.config/hypr/.theme-mode")
THEME_SCRIPT = os.path.expanduser("~/.config/hypr/scripts/theme-toggle.sh")

class ThemeCard(Gtk.Window):
    def __init__(self):
        super().__init__()
        
        # Configuración de ventana
        self.set_title("Theme Toggle")
        self.set_default_size(140, 180)
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
        self.flip_progress = 1.0 if self.is_light else 0.0  # Estado actual
        
        # 🔄 Toggle automático al abrir
        self.is_light = not self.is_light
        self.target_flip = 1.0 if self.is_light else 0.0
        
        # Guardar y aplicar tema inmediatamente
        self.save_theme(self.is_light)
        
        self.hover = False
        self.animation_done = False
        
        # Drawing area
        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.connect('draw', self.on_draw)
        self.add(self.drawing_area)
        
        # NO necesitamos eventos de mouse ya que el cambio es automático
        
        # Animación
        GLib.timeout_add(16, self.animate)  # ~60 FPS
        
        # Cerrar automáticamente después de la animación (1.5 segundos)
        GLib.timeout_add(1500, self.auto_close)
        
        self.show_all()
    
    def load_theme(self):
        """Cargar tema actual desde archivo"""
        try:
            with open(THEME_FILE, 'r') as f:
                return f.read().strip() == 'light'
        except:
            return False  # Default dark
    
    def save_theme(self, is_light):
        """Guardar tema y ejecutar script"""
        theme = 'light' if is_light else 'dark'
        
        # Guardar en archivo
        with open(THEME_FILE, 'w') as f:
            f.write(theme)
        
        # Ejecutar script de cambio de tema en background
        subprocess.Popen([
            'bash', THEME_SCRIPT, 'silent', theme
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    def auto_close(self):
        """Cerrar ventana automáticamente después de la animación"""
        self.destroy()
        return False  # No repetir
    
    def animate(self):
        """Animación de flip"""
        # Interpolar hacia el objetivo
        diff = self.target_flip - self.flip_progress
        if abs(diff) > 0.01:
            self.flip_progress += diff * 0.18  # Velocidad de animación (más rápido)
            self.queue_draw()
        else:
            self.flip_progress = self.target_flip
            self.animation_done = True
        
        return True  # Continuar animación
    
    def on_draw(self, widget, cr):
        """Renderizar la tarjeta"""
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        
        # Fondo transparente
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(cairo.Operator.SOURCE)
        cr.paint()
        cr.set_operator(cairo.Operator.OVER)
        
        # Centro de la tarjeta
        card_size = min(width, height - 40)
        x = (width - card_size) / 2
        y = 10
        
        # ═══════════════════════════════════════════════════════
        #  🎴 DIBUJAR TARJETA CON FLIP
        # ═══════════════════════════════════════════════════════
        
        # Calcular rotación (0-180 grados)
        angle = self.flip_progress * math.pi
        scale_x = abs(math.cos(angle))
        
        # Transformación 3D perspectiva
        cr.save()
        cr.translate(width / 2, y + card_size / 2)
        cr.scale(scale_x if scale_x > 0.1 else 0.1, 1.0)
        cr.translate(-card_size / 2, -card_size / 2)
        
        # Dibujar cara correcta según el ángulo
        if math.cos(angle) >= 0:
            # Cara frontal (dark)
            self.draw_dark_card(cr, card_size)
        else:
            # Cara trasera (light) - invertir horizontalmente
            cr.scale(-1, 1)
            cr.translate(-card_size, 0)
            self.draw_light_card(cr, card_size)
        
        cr.restore()
        
        # ═══════════════════════════════════════════════════════
        #  📝 LABEL
        # ═══════════════════════════════════════════════════════
        label = "Light Mode" if self.is_light else "Dark Mode"
        cr.select_font_face("JetBrainsMono Nerd Font", 
                           cairo.FONT_SLANT_NORMAL, 
                           cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(14)
        
        # Sombra del texto
        extents = cr.text_extents(label)
        text_x = (width - extents.width) / 2
        text_y = height - 15
        
        cr.set_source_rgba(0, 0, 0, 0.7)
        cr.move_to(text_x + 1, text_y + 1)
        cr.show_text(label)
        
        # Texto
        cr.set_source_rgba(1, 1, 1, 0.95)
        cr.move_to(text_x, text_y)
        cr.show_text(label)
    
    def draw_dark_card(self, cr, size):
        """Dibujar escena de noche"""
        # Fondo nocturno
        gradient = cairo.LinearGradient(0, 0, 0, size)
        gradient.add_color_stop_rgb(0, 0.04, 0.05, 0.15)      # #0a0e27
        gradient.add_color_stop_rgb(0.4, 0.1, 0.12, 0.23)     # #1a1f3a
        gradient.add_color_stop_rgb(1, 0.18, 0.11, 0.24)      # #2d1b3d
        
        self.draw_rounded_rect(cr, 0, 0, size, size, 24)
        cr.set_source(gradient)
        cr.fill_preserve()
        
        # Borde sutil
        cr.set_source_rgba(1, 1, 1, 0.1)
        cr.set_line_width(1)
        cr.stroke()
        
        # Luna
        moon_x, moon_y = size * 0.75, size * 0.2
        cr.arc(moon_x, moon_y, 15, 0, 2 * math.pi)
        cr.set_source_rgba(1, 0.98, 0.9, 1)
        cr.fill()
        
        # Resplandor de la luna
        cr.arc(moon_x, moon_y, 20, 0, 2 * math.pi)
        cr.set_source_rgba(1, 0.98, 0.9, 0.2)
        cr.fill()
        
        # Estrellas
        stars = [
            (size * 0.2, size * 0.15),
            (size * 0.7, size * 0.25),
            (size * 0.4, size * 0.35),
            (size * 0.6, size * 0.1),
            (size * 0.85, size * 0.3),
        ]
        
        for sx, sy in stars:
            cr.arc(sx, sy, 1.5, 0, 2 * math.pi)
            cr.set_source_rgba(1, 1, 1, 0.9)
            cr.fill()
        
        # Suelo
        ground_gradient = cairo.LinearGradient(0, size * 0.75, 0, size)
        ground_gradient.add_color_stop_rgb(0, 0.1, 0.12, 0.23)
        ground_gradient.add_color_stop_rgb(1, 0.05, 0.07, 0.09)
        
        cr.rectangle(0, size * 0.75, size, size * 0.25)
        cr.set_source(ground_gradient)
        cr.fill()
    
    def draw_light_card(self, cr, size):
        """Dibujar escena de día"""
        # Cielo diurno
        gradient = cairo.LinearGradient(0, 0, 0, size)
        gradient.add_color_stop_rgb(0, 0.53, 0.81, 0.92)      # #87CEEB
        gradient.add_color_stop_rgb(0.5, 0.69, 0.89, 1.0)     # #B0E2FF
        gradient.add_color_stop_rgb(1, 0.56, 0.93, 0.56)      # #90EE90
        
        self.draw_rounded_rect(cr, 0, 0, size, size, 24)
        cr.set_source(gradient)
        cr.fill_preserve()
        
        # Borde
        cr.set_source_rgba(1, 1, 1, 0.3)
        cr.set_line_width(1)
        cr.stroke()
        
        # Sol
        sun_x, sun_y = size * 0.75, size * 0.2
        
        # Resplandor externo
        cr.arc(sun_x, sun_y, 25, 0, 2 * math.pi)
        cr.set_source_rgba(1, 0.84, 0, 0.2)
        cr.fill()
        
        # Resplandor medio
        cr.arc(sun_x, sun_y, 20, 0, 2 * math.pi)
        cr.set_source_rgba(1, 0.84, 0, 0.4)
        cr.fill()
        
        # Sol principal
        cr.arc(sun_x, sun_y, 17, 0, 2 * math.pi)
        cr.set_source_rgba(1, 0.84, 0, 1)
        cr.fill()
        
        # Nubes
        clouds = [
            (size * 0.2, size * 0.2, 0.35, 0.1),
            (size * 0.7, size * 0.35, 0.45, 0.12),
            (size * 0.35, size * 0.5, 0.3, 0.08),
        ]
        
        for cx, cy, width_ratio, height_ratio in clouds:
            cloud_w = size * width_ratio
            cloud_h = size * height_ratio
            
            cr.save()
            cr.translate(cx, cy)
            cr.scale(cloud_w / 2, cloud_h / 2)
            cr.arc(0, 0, 1, 0, 2 * math.pi)
            cr.restore()
            
            cr.set_source_rgba(1, 1, 1, 0.7)
            cr.fill()
        
        # Césped
        grass_gradient = cairo.LinearGradient(0, size * 0.75, 0, size)
        grass_gradient.add_color_stop_rgb(0, 0.56, 0.93, 0.56)
        grass_gradient.add_color_stop_rgb(1, 0.2, 0.8, 0.2)
        
        cr.rectangle(0, size * 0.75, size, size * 0.25)
        cr.set_source(grass_gradient)
        cr.fill()
    
    def draw_rounded_rect(self, cr, x, y, width, height, radius):
        """Dibujar rectángulo con bordes redondeados"""
        cr.new_sub_path()
        cr.arc(x + radius, y + radius, radius, math.pi, 3 * math.pi / 2)
        cr.arc(x + width - radius, y + radius, radius, 3 * math.pi / 2, 0)
        cr.arc(x + width - radius, y + height - radius, radius, 0, math.pi / 2)
        cr.arc(x + radius, y + height - radius, radius, math.pi / 2, math.pi)
        cr.close_path()

if __name__ == '__main__':
    win = ThemeCard()
    win.connect('destroy', Gtk.main_quit)
    Gtk.main()
