from pathlib import Path
import runpy
import unittest

ROOT = Path(__file__).resolve().parents[1]
THEMED = ROOT / "Thinkpad/local/share/solace/default/themed"
colors = runpy.run_path(str(THEMED / "impala-selection.py"))


class ImpalaSelectionTests(unittest.TestCase):
    def test_light_and_dark_selections_are_readable_and_distinct(self):
        for palette in (
            {"background": "#101017", "foreground": "#dddde7", "accent": "#b4a1e8"},
            {"background": "#00020a", "foreground": "#ffffff", "accent": "#3b6aa5"},
            {"background": "#fafafa", "foreground": "#111111", "accent": "#8054a8"},
        ):
            with self.subTest(palette=palette):
                selection = colors["selection_color"](palette)
                self.assertGreaterEqual(colors["contrast"](selection, palette["foreground"]), 4.5)
                self.assertGreaterEqual(colors["contrast"](selection, palette["background"]), 3.0)

    def test_template_uses_selection_fill_not_terminal_background(self):
        template = (THEMED / "impala.toml.tpl").read_text()
        self.assertIn('background = "{{ impala_selection_background }}"', template)
        self.assertIn('text_color = "{{ foreground }}"', template)

    def test_invalid_palette_is_rejected(self):
        with self.assertRaises(ValueError):
            colors["selection_color"]({"background": "red", "foreground": "#ffffff", "accent": "#00ff00"})
