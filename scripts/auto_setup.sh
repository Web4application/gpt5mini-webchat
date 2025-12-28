#!/bin/bash
set -e
set -o pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# --- CONFIGURATION ---
ESP_DIR="$HOME/esp"
ESP_IDF_VERSION="v5.5.1"
TARGET_CHIPS=("esp32c3" "esp32" "esp32s2")
PROJECT_DIR="$PWD"
PORT="/dev/ttyUSB0"
GITHUB_OWNER="your_github_username"
GITHUB_TOKEN="your_github_token"
LIGHTHOUSE_URL="http://localhost"
REPORT_TITLE="RODA Lighthouse Report"

# --- HELPER FUNCTION ---
install_if_missing() {
  local cmd=$1
  local pkg=$2
  if ! command -v "$cmd" &> /dev/null; then
    log "$cmd not found, installing $pkg..."
    apt-get install -y "$pkg"
  else
    log "$cmd already installed, skipping."
  fi
}

# --- ESP-IDF SETUP ---
log "Setting up ESP-IDF..."
mkdir -p "$ESP_DIR"
cd "$ESP_DIR"
if [ ! -d "esp-idf" ]; then
  log "Cloning ESP-IDF $ESP_IDF_VERSION..."
  git clone -b $ESP_IDF_VERSION --recursive https://github.com/espressif/esp-idf.git
else
  log "ESP-IDF already cloned, pulling latest..."
  cd esp-idf
  git fetch && git checkout $ESP_IDF_VERSION && git submodule update --init --recursive
fi
cd esp-idf

for chip in "${TARGET_CHIPS[@]}"; do
  log "Installing ESP-IDF tools for $chip..."
  ./install.sh "$chip"
done

export IDF_GITHUB_ASSETS="dl.espressif.com/github_assets"
./install.sh

log "ESP-IDF setup complete."

# --- BUILD AND FLASH ---
log "Building ESP project..."
cd "$PROJECT_DIR"
idf.py build

log "Flashing ESP device..."
idf.py -p "$PORT" flash

# --- NODE.JS + LIGHTHOUSE ---
log "Installing Node.js, npm, Chromium, jq if missing..."
install_if_missing node nodejs
install_if_missing npm npm
install_if_missing chromium chromium
install_if_missing jq jq

log "Installing Lighthouse globally..."
if ! command -v lighthouse &> /dev/null; then
  npm install -g lighthouse
else
  log "Lighthouse already installed, skipping."
fi

# --- RUN LIGHTHOUSE ---
log "Running Lighthouse on $LIGHTHOUSE_URL..."
LIGHTHOUSE_JSON=$(lighthouse "$LIGHTHOUSE_URL" --chrome-flags="--no-sandbox --headless" --output json | \
  jq -r "{ description: \"gh.io\", public: false, files: {\"$(date '+%Y%m%d').lighthouse.report.json\": {content: (. | tostring) }}}")

log "Uploading Lighthouse report to GitHub Gist..."
echo "$LIGHTHOUSE_JSON" | curl -sS -X POST -H "Content-Type: application/json" \
  -u "$GITHUB_OWNER:$GITHUB_TOKEN" \
  -d @- https://api.github.com/gists > results.gist

GID=$(jq -r '.id' results.gist)
log "Updating Gist description with Lighthouse Viewer link..."
curl -sS -X PATCH -H "Content-Type: application/json" \
  -u "$GITHUB_OWNER:$GITHUB_TOKEN" \
  -d "{ \"description\": \"$REPORT_TITLE - Lighthouse: https://googlechrome.github.io/lighthouse/viewer/?gist=${GID}\" }" \
  "https://api.github.com/gists/${GID}" > updated.gist

log "Automation complete! Gist ID: $GID"
