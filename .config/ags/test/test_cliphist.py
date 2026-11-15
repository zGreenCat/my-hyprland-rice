import importlib.util
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parent.parent / "widget" / "clipboard" / "cliphist.py"
spec = importlib.util.spec_from_file_location("cliphist_helper", HELPER)
cliphist = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cliphist)


class DetectType(unittest.TestCase):
    def test_imagen(self):
        self.assertEqual(cliphist.detect_type("[[ binary data 36 KiB png 458x150 ]]"), "image")

    def test_enlace(self):
        self.assertEqual(cliphist.detect_type("https://wiki.hyprland.org/Configuring/Animations/"), "link")

    def test_enlace_con_espacios_es_texto(self):
        self.assertEqual(cliphist.detect_type("mira https://wiki.hyprland.org"), "text")

    def test_colores(self):
        for value in ("#cba6f7", "#fff", "rgb(203, 166, 247)", "hsl(270, 80%, 81%)"):
            with self.subTest(value=value):
                self.assertEqual(cliphist.detect_type(value), "color")

    def test_hex_invalido_es_texto(self):
        self.assertEqual(cliphist.detect_type("#zzzzzz"), "text")

    def test_texto(self):
        self.assertEqual(cliphist.detect_type("pkill -x waybar; sleep 1"), "text")


class Etiquetas(unittest.TestCase):
    def test_display_quita_id(self):
        self.assertEqual(cliphist.display_text("7398\thttps://example.com"), "https://example.com")

    def test_one_line(self):
        self.assertEqual(cliphist.one_line("uno\n  dos\tTres "), "uno dos Tres")

    def test_image_label_con_dimensiones(self):
        self.assertEqual(cliphist.image_label("[[ binary data 36 KiB png 458x150 ]]"), "Imagen · 458×150")

    def test_image_label_sin_dimensiones(self):
        self.assertEqual(cliphist.image_label("[[ binary data 2 KiB bmp ]]"), "Imagen")

    def test_image_dimensions(self):
        self.assertEqual(cliphist.image_dimensions("[[ binary data 36 KiB png 458x150 ]]"), "458×150")
        self.assertIsNone(cliphist.image_dimensions("[[ binary data 2 KiB bmp ]]"))

    def test_describe_text(self):
        self.assertEqual(cliphist.describe_text("hola"), "1 línea · 4 caracteres")
        self.assertEqual(cliphist.describe_text("a\nb\nc"), "3 líneas · 5 caracteres")


if __name__ == "__main__":
    unittest.main()
