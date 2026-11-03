# Cadastra brand

**Survey C**: a boundary pillar seen from above, opened on the right into a C, around a gold survey point.

| File | Use |
|---|---|
| `mark.svg` | The mark on light backgrounds |
| `mark-white.svg` | The mark on dark or green backgrounds |
| `app-icon.svg` | Full-bleed app icon (iOS, Android adaptive); platforms round the corners |
| `app-icon-rounded.svg` | Icon with its own rounded corners (Android legacy launcher, favicons) |

Construction (100-unit grid): diamond 8–92, stroke 13 with mitred corners, open from the midpoint of each right-hand
edge (71,29 → 71,71), point radius 10 at the centre. Keep half the mark's height clear around it. Smallest sizes:
16 px on screen, 5 mm in print.

| Colour | Hex | |
|---|---|---|
| Survey green | `#0B6E4F` | Mark, primary actions |
| Ink | `#0F1B17` | Text, dark backgrounds |
| Beacon gold | `#E0A526` | The point and small accents only, never text on white |
| Ground | `#F4F6F4` | Page background |

Wordmark: IBM Plex Sans Bold, tracking −1.5 %. Descriptor: IBM Plex Mono Medium, capitals, tracking 22 %.

App icons in `web/` and `mobile/` are rendered from these files by `brand/render-icons.mjs`.
