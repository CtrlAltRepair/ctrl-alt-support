# macOS code signing + notarization — Ctrl Alt Support

This documents the GitHub **repository secrets** the `build-for-macOS` job in
`.github/workflows/flutter-build.yml` needs to produce a **Developer-ID-signed +
notarized + stapled** `Ctrl Alt Support.app` (and `.dmg`).

If `MACOS_P12_BASE64` is **not** set, the job still builds and uploads the
**unsigned** app exactly as before — every signing/notarization step is gated on
`env.MACOS_P12_BASE64 != null`. So nothing breaks until you add the secrets.

## Why signing matters (the 3 problems it fixes)

1. **Gatekeeper "unidentified developer".** An unsigned (or ad-hoc signed) app has
   no trusted developer identity, so Gatekeeper blocks it. A **Developer ID
   Application** signature + **notarization** (Apple scans the binary and issues a
   ticket) + **stapling** (the ticket is embedded in the app/dmg) makes Gatekeeper
   open it without warnings, even offline.
2. **Screen Recording / Accessibility (TCC) not persisting across rebuilds.** macOS
   keys TCC permission grants to the app's **code-signing identity** (Team ID +
   bundle ID designated requirement), not the file path. An unsigned/ad-hoc build
   gets a *different* identity every rebuild, so macOS treats each new build as a
   stranger and drops the grants. A stable Developer ID identity keeps the same
   designated requirement across rebuilds, so Screen Recording / Accessibility
   grants stick.
3. **In-app "Install system service" (LaunchDaemon) silently failing.** Installing a
   start-on-boot LaunchDaemon on modern macOS requires a properly signed (and, for
   distribution, notarized) executable. The embedded `service` binary lives inside
   the bundle and is signed by the `--deep` codesign, so the daemon loads instead
   of being silently rejected.

## Recommended notarization method (already wired)

**App Store Connect API key (`.p8`) + Apple's `xcrun notarytool`.** This is the
simplest *reliable* option for CI:

- Three values come straight from a web page (no local CLI gymnastics).
- API keys **do not expire** (unlike Apple-ID app-specific passwords, which can be
  revoked/invalidated and are tied to a personal Apple ID).
- `notarytool` + `stapler` ship with Xcode and are already on the `macos-14` runner
  — no extra tool download.

(The previous `rcodesign` + combined-JSON path was removed; it required encoding a
key JSON with a tool you'd have to run locally.)

---

## Secrets to add

GitHub → repo **Settings → Secrets and variables → Actions → New repository secret**.

| Secret name | What it is |
|---|---|
| `MACOS_P12_BASE64` | Developer ID Application certificate **+ its private key**, exported as a `.p12`, then base64-encoded. |
| `MACOS_P12_PASSWORD` | The password you set when exporting that `.p12`. |
| `MACOS_CODESIGN_IDENTITY` | The signing identity string, e.g. `Developer ID Application: Ctrl Alt Repair LLC (XXXXXXXXXX)` (or its 40-char SHA-1 hash). |
| `MACOS_NOTARY_API_KEY_P8_BASE64` | The App Store Connect API key file `AuthKey_XXXXXXXXXX.p8`, base64-encoded. |
| `MACOS_NOTARY_API_KEY_ID` | The API **Key ID** (~10 chars, e.g. `2X9R4HXF34`). |
| `MACOS_NOTARY_API_ISSUER_ID` | The API **Issuer ID** (a UUID, e.g. `69a6de7e-...`). |

You will also need your **Team ID** (10 chars, e.g. `AB12CD34EF`) — it is the part
in parentheses inside `MACOS_CODESIGN_IDENTITY`. It is not a separate secret in this
setup, but record it.

---

## How to obtain each value

### 1. Developer ID Application certificate → `MACOS_P12_BASE64` + `MACOS_P12_PASSWORD`

Prereq: a paid **Apple Developer Program** membership for Ctrl Alt Repair LLC.

1. Create the cert (once): https://developer.apple.com/account → **Certificates,
   IDs & Profiles → Certificates → +** → choose **Developer ID Application** →
   follow the CSR steps (Keychain Access → Certificate Assistant → *Request a
   Certificate from a Certificate Authority*). Download the `.cer` and double-click
   to install it into your login keychain.
2. Export as `.p12`: open **Keychain Access** → **login** keychain → **My
   Certificates** → expand the `Developer ID Application: Ctrl Alt Repair LLC (…)`
   row so you can see the **private key** under it → select the certificate **and**
   its private key → right-click → **Export 2 items…** → format **Personal
   Information Exchange (.p12)** → save as `ctrl-alt-support-developer-id.p12` →
   set a strong password when prompted. **That password is `MACOS_P12_PASSWORD`.**
   (If you can't expand to a private key, the cert has no key — recreate it.)
3. base64-encode the `.p12`:
   ```sh
   base64 -i ctrl-alt-support-developer-id.p12 -o p12.b64
   ```
   The contents of `p12.b64` is `MACOS_P12_BASE64`.

### 2. Signing identity string → `MACOS_CODESIGN_IDENTITY`

With the cert installed in your keychain:
```sh
security find-identity -v -p codesigning
```
Copy the quoted name exactly, e.g.:
`Developer ID Application: Ctrl Alt Repair LLC (AB12CD34EF)`
That whole string is `MACOS_CODESIGN_IDENTITY`. (The 40-hex SHA-1 hash shown to the
left also works and avoids quoting issues.) The `AB12CD34EF` inside the parentheses
is your **Team ID**.

### 3. App Store Connect API key → `MACOS_NOTARY_API_KEY_P8_BASE64`, `MACOS_NOTARY_API_KEY_ID`, `MACOS_NOTARY_API_ISSUER_ID`

1. Go to https://appstoreconnect.apple.com → **Users and Access** → **Integrations**
   tab → **App Store Connect API** (Keys). (Use the **Team Keys** section.)
2. Click **+** to generate a key. Give it a name; for **Access** choose a role that
   can notarize — **Developer** is sufficient. Click **Generate**.
3. **Download the `AuthKey_XXXXXXXXXX.p8` now** — Apple lets you download it **only
   once**. Keep it secret.
4. From that page:
   - The **Key ID** (the `XXXXXXXXXX` in the filename, ~10 chars) → `MACOS_NOTARY_API_KEY_ID`.
   - The **Issuer ID** (UUID shown at the top of the Keys list) → `MACOS_NOTARY_API_ISSUER_ID`.
5. base64-encode the `.p8`:
   ```sh
   base64 -i AuthKey_XXXXXXXXXX.p8 -o p8.b64
   ```
   The contents of `p8.b64` is `MACOS_NOTARY_API_KEY_P8_BASE64`.

---

## Alternative (NOT wired): Apple-ID app-specific password

If you ever can't get an App Store Connect API key, `notarytool` also accepts:
```
xcrun notarytool submit <file> --apple-id <apple-id-email> \
  --team-id <TEAMID> --password <app-specific-password> --wait
```
where the app-specific password comes from https://account.apple.com → Sign-In &
Security → App-Specific Passwords. We do **not** recommend this for CI (passwords
expire/can be revoked and are tied to a personal Apple ID), and the workflow is not
currently set up for it.

---

## After adding the secrets

Run the workflow (manual dispatch / nightly). The macOS job will:
codesign the app (hardened runtime + `Release.entitlements`) → notarize + staple the
app → build the dmg → codesign + notarize + staple the dmg → upload it as the
`rustdesk-signed-macos-aarch64` artifact.

Quick local verification of a downloaded build:
```sh
spctl -a -t exec -vvv "/Applications/Ctrl Alt Support.app"   # should say: accepted, source=Notarized Developer ID
codesign -dvvv "/Applications/Ctrl Alt Support.app"          # check Authority / TeamIdentifier
xcrun stapler validate "/Applications/Ctrl Alt Support.app"  # should say: worked
```

---

## ⚠️ Cross-track dependency: server re-key

A parallel effort is rebuilding the RustDesk **server with a new key**. The brand
patch in this workflow bakes a server public key into the client via
`RS_PUB_KEY` / `config.rs` (currently `v30irCuJA85ZaZnFIMC4Ne6Uzcz9vYPVnmbGx4PCrV4=`,
server `support.ctrlaltrepair.com`). **The final signed client must embed the NEW
server key.** Before producing the final signed release, rebase/merge this `signing`
branch onto `master` once master carries the re-key, and confirm the brand-patch
strings match the new key — otherwise you'll ship a correctly-signed client that
can't reach the server.
