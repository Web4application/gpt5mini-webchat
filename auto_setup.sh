#!/bin/bash
set -e  # Exit immediately if a command fails
set -o pipefail

# --- CONFIGURATION ---
ESP_DIR="$HOME/esp"
ESP_IDF_VERSION="v5.5.1"
TARGET_CHIPS=("esp32c3" "esp32" "esp32s2")  # adjust as needed
PROJECT_DIR="$PWD"  # your ESP project folder
PORT="/dev/ttyUSB0"  # adjust for your device
GITHUB_OWNER="your_github_username"
GITHUB_TOKEN="your_github_token"
LIGHTHOUSE_URL="http://localhost"
REPORT_TITLE="RODA Lighthouse Report"

# --- ESP-IDF SETUP ---
echo "==> Setting up ESP-IDF..."
mkdir -p "$ESP_DIR"
cd "$ESP_DIR"
if [ ! -d "esp-idf" ]; then
  git clone -b $ESP_IDF_VERSION --recursive https://github.com/espressif/esp-idf.git
fi
cd esp-idf

# Install for all targets
for chip in "${TARGET_CHIPS[@]}"; do
  echo "Installing ESP-IDF for $chip..."
  ./install.sh "$chip"
done

# Optional: install all assets
export IDF_GITHUB_ASSETS="dl.espressif.com/github_assets"
./install.sh

echo "ESP-IDF setup complete."

# --- BUILD AND FLASH PROJECT ---
echo "==> Building ESP project..."
cd "$PROJECT_DIR"
idf.py build

echo "==> Flashing ESP device..."
idf.py -p "$PORT" flash

echo "ESP build & flash complete."

# --- NODE.JS & LIGHTHOUSE ---
echo "==> Installing Node.js, npm, Chromium, jq, Lighthouse..."
apt-get install -y nodejs npm chromium jq
npm install -g lighthouse

# Run Lighthouse headless, pipe JSON to GitHub Gist
echo "==> Running Lighthouse..."
LIGHTHOUSE_JSON=$(lighthouse "$LIGHTHOUSE_URL" --chrome-flags="--no-sandbox --headless" --output json | jq -r "{ description: \"gh.io\", public: false, files: {\"$(date "+%Y%m%d").lighthouse.report.json\": {content: (. | tostring) }}}")

echo "$LIGHTHOUSE_JSON" | curl -sS -X POST -H "Content-Type: application/json" \
  -u "$GITHUB_OWNER:$GITHUB_TOKEN" \
  -d @- https://api.github.com/gists > results.gist

# Update Gist description with Lighthouse Viewer link
GID=$(cat results.gist | jq -r '.id')
curl -sS -X PATCH -H "Content-Type: application/json" \
  -u "$GITHUB_OWNER:$GITHUB_TOKEN" \
  -d "{ \"description\": \"$REPORT_TITLE - Lighthouse: https://googlechrome.github.io/lighthouse/viewer/?gist=${GID}\" }" \
  "https://api.github.com/gists/${GID}" > updated.gist

echo "==> Automation complete! Gist ID: $GID"
