# Branding assets — PLACEHOLDERS

Every image in this folder is a **placeholder** (a plain teal square) until the project
owner supplies the real logo and icon. Replace each file in place, keeping the name and
size, then regenerate the native files:

```bash
dart run flutter_launcher_icons       # app icons (config: flutter_launcher_icons.yaml)
dart run flutter_native_splash:create # launch screens (config: flutter_native_splash.yaml)
```

| File | Size | What goes in it |
| --- | --- | --- |
| `icon.png` | 1024 × 1024, no transparency | App icon: the character alone on a plain background, no wordmark. Used for iOS and legacy Android icons. |
| `icon_foreground.png` | 1024 × 1024, transparent | Android adaptive-icon foreground: the character, kept inside the central 66% safe zone. The background layer is the colour `adaptive_icon_background` in `flutter_launcher_icons.yaml`. |
| `splash_logo.png` | 768 × 768 (drawn at 4×, shows at 192 dp) | Launch screen on iOS and Android 8–11: the full logo (character + *BAH!* / *FRANÇAIS* wordmark), transparent background. |
| `splash_logo_android12.png` | 1152 × 1152, transparent | Launch screen on Android 12+: the system crops this to a circle 768 px across, so it should hold the character alone, inside that circle. |

The launch screen background is white in light mode and navy `#14334C` in dark mode,
following the phone's setting. The logo must read on both.
