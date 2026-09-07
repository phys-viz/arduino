# Builds a self-contained environment for the compile server — arduino-cli
# and the AVR board support get installed INSIDE this image, at a fixed,
# known location, every single time it's built. This is what makes a
# hosted deploy reliable: no more "which folder is it actually in on this
# particular computer" — there's exactly one computer, and we built it.

FROM node:20-slim

# Install curl just long enough to fetch arduino-cli, then remove it —
# keeps the final image smaller.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
  && curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=/usr/local/bin sh \
  && apt-get purge -y curl \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

# Pull in the AVR board support (Uno/Nano) so it's baked into the image —
# no separate one-time setup step needed after deploying, unlike the
# manual `arduino-cli core install` step we ran by hand on your laptop.
RUN arduino-cli core update-index && arduino-cli core install arduino:avr

# Any library your sketches need (beyond the built-in core) goes in
# libraries.txt, one name per line — same names you'd pass to
# `arduino-cli lib install`. Add a new line there any time a unit needs
# a new library, then redeploy, instead of hand-installing it again.
COPY libraries.txt ./
RUN xargs -a libraries.txt -I{} arduino-cli lib install "{}"

# Tell server.js that arduino-cli is just "arduino-cli" in here (it's on
# the PATH at /usr/local/bin) — this OVERRIDES the Windows-path fallback
# that's still in the source file for when it runs on your own laptop.
ENV ARDUINO_CLI_PATH=arduino-cli

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./

EXPOSE 3131
ENV PORT=3131
CMD ["node", "server.js"]
