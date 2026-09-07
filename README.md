# Zio Arduino — a classroom Arduino uploader

Replaces Arduino Create's browser editor for a classroom of Uno/Nano boards.
Students write code, click **Compile**, click **Connect board**, click
**Upload** — the program goes straight from their browser to their USB
board, with no cloud agent in between.

There are two pieces:

- `server/` — a small compile server. It needs to run somewhere with
  `arduino-cli` installed. It never touches USB — its only job is turning
  code into a `.hex` file.
- `public/index.html` — the page students use. It has the editor and does
  the actual USB upload, using the browser's WebSerial API.

## 1. Set up the compile server

On whatever machine will run it (your own laptop is fine to start):

```bash
# Install arduino-cli: https://arduino.github.io/arduino-cli/latest/installation/
arduino-cli core update-index
arduino-cli core install arduino:avr

cd server
npm install
node server.js
```

It listens on port 3131 by default. Test it's alive:
`curl http://localhost:3131/health` should return `{"ok":true}`.

## 2. Point the student page at your compile server

Open `public/index.html`, find this line near the top of the `<script>`:

```js
const COMPILE_SERVER_URL = "http://localhost:3131";
```

Change it to wherever the server actually is:
- Same classroom, server on your laptop: your laptop's LAN IP, e.g.
  `http://192.168.1.50:3131`
- Server hosted somewhere on the internet (Render, Railway, Fly.io, a
  school-approved VPS, etc.): its public URL, e.g.
  `https://your-server.onrender.com`

## 3. Host the student page somewhere reachable

**Do not use GitHub Pages** — you've mentioned your school network blocks
GitHub outright, so students won't be able to load the page at all.

For WebSerial to work reliably for 60 different Chromebooks, the page
needs to be served over **HTTPS** (or from `localhost` on each machine,
which isn't practical here). Easiest free options that aren't GitHub:

- **Netlify** or **Vercel** — drag-and-drop the `public/` folder, get an
  HTTPS URL in under a minute.
- **Cloudflare Pages** — similar, also free.

If your school network blocks those too, running the whole thing
(student page *and* compile server together) from your own laptop on the
classroom LAN with a real local HTTPS certificate is possible but more
setup (tools like `mkcert` can help) — let me know if you end up needing
that route and we can go through it.

## Browser requirement

WebSerial only works in **Chrome or Edge** (not Safari, not Firefox). If
your students are on Chromebooks, you're fine — ChromeOS's Chrome
supports it.

## Honest caveats before you roll this out to 60 students

- The "talk to the bootloader" step (STK500) is a real low-level USB
  protocol. I've implemented it from the documented spec, but I can't
  test it against a physical Uno or Nano myself. **Test with one board
  first.** If sync fails, the most common fixes are: press the board's
  physical reset button right as it says "Syncing...", or double-check
  you picked the right board type in the dropdown (older Nanos use a
  different bootloader and baud rate than Unos).
- Only one browser tab can hold a serial connection to a board at a time
  — normal, not a bug, if a student sees "port already open" after
  refreshing without disconnecting.
- The compile server runs a real compiler on whatever code is submitted.
  It's sandboxed to temp folders and has a 25-second timeout per compile,
  but if you host it publicly (not just on your classroom LAN), it's
  worth putting it behind something only your students can reach.

## Trying it locally before deployment day

You can test everything on one machine: run the server, open
`public/index.html` directly in Chrome (as a `file://` page WebSerial
still works, since `file://` counts as a secure context), plug in one
Arduino, and go through Compile → Connect → Upload.
