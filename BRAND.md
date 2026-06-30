# Ctrl Alt Repair — Brand Spec (for the Ctrl Alt Support client)

Source of truth: OneDrive → `Ctrl Alt Repair/Company Files/Marketing & Branding/Templates/Ctrl Alt Repair color pallet.docx`

## Color swatch (official)
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Light Gray | `#ECECEC` | 236,236,236 | window/section backgrounds |
| Gray | `#767575` | 118,117,117 | secondary text, muted UI |
| Dark Gray | `#2C2C2C` | 44,44,44 | primary text, dark surfaces, title bars |
| Orange‑Red (accent) | `#FF4100` | 255,65,0 | primary buttons, highlights, links, active states |

Flutter ARGB for the accent: `Color(0xFFFF4100)`. Replace ALL stock RustDesk blues (`0xFF0071FF`, `Colors.blue*`) and the pink/magenta install-banner gradient with these.

## Fonts
Corbel (body) / Corbert (display) — brand fonts. (App keeps its bundled UI font; brand fonts are for marketing/site.)

## Naming / text
- App name: **Ctrl Alt Support**
- Footer/credit: **"Powered by Ctrl Alt Repair"** (never "Powered by RustDesk")
- Server (baked in): `support.ctrlaltrepair.com`, key `77r7AVtxvxjzfTZBm4cHC2kWMiD3WCBhaDjrcGCxv20=`

## Icon
Brand mark = the **Ctrl / Alt / Repair keyboard keys** (OneDrive `Logos/CtrlAltRepair_Logo_v3.7.png` and round badge `Logo - Keyboard Keys Design.png`). App icon: keyboard-keys mark on an `#FF4100` rounded square (macOS/Windows app-icon style). No stock RustDesk blue-circle icon.
