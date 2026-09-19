#!/usr/bin/env bash
set -e

# viLilt TestFlight Build & Upload Script (Tier 1: Impact / Nonprofit)
# Team ID: 43SKUJ8Z35 (viaiforgood)
# Bundle ID: org.viaiforgood.vililt

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

if [ -d "/Applications/Xcode-beta.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
elif [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "=================================================="
echo "🚀 Starting viLilt TestFlight Build Pipeline (viaiforgood)"
echo "=================================================="
echo "Using Xcode Developer Dir: ${DEVELOPER_DIR:-$(xcode-select -p)}"

# 1. Switch project to Impact configuration
python3 scripts/switch_target_tier.py impact

# 2. Clean previous build artifacts
rm -rf build/viLilt.xcarchive build/export_tf
mkdir -p build

# 3. Build Archive
echo "📦 Creating Xcode Release Archive for viLilt..."
xcodebuild archive \
  -project ViLilt.xcodeproj \
  -scheme ViLilt \
  -destination 'generic/platform=iOS' \
  -archivePath build/viLilt.xcarchive \
  -configuration Release \
  -allowProvisioningUpdates \
  CODE_SIGNING_ALLOWED=NO

echo "✅ Archive created successfully at build/viLilt.xcarchive"

# 4. Patch SDK version metadata for App Store Connect ingestion
echo "🛠️ Patching Xcode SDK metadata..."
python3 scripts/patch_archive_xcode_version.py build/viLilt.xcarchive

# 5. Upload to App Store Connect / TestFlight (viaiforgood)
echo "📤 Uploading archive to App Store Connect (viaiforgood)..."
AUTH_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_HF628QL73G.p8"
AUTH_KEY_ID="HF628QL73G"
AUTH_KEY_ISSUER="1952449e-2b2a-4b8b-bc2e-a51af7c12d19"

if [ -f "$AUTH_KEY_PATH" ]; then
  xcodebuild -exportArchive \
    -archivePath build/viLilt.xcarchive \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath build/export_tf \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$AUTH_KEY_PATH" \
    -authenticationKeyID "$AUTH_KEY_ID" \
    -authenticationKeyIssuerID "$AUTH_KEY_ISSUER"
else
  xcodebuild -exportArchive \
    -archivePath build/viLilt.xcarchive \
    -exportOptionsPlist ExportOptions.plist \
    -exportPath build/export_tf \
    -allowProvisioningUpdates
fi

echo "=================================================="
echo "🎉 viLilt (Impact) TestFlight Build & Upload Complete!"
echo "=================================================="
