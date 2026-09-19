#!/usr/bin/env bash
set -e

# viLilt Pro TestFlight Build & Upload Script (Tier 2: Commercial Base)
# Team ID: 3PY896HD7X (VI AI INC)
# Bundle ID: com.vi.vililt

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

if [ -d "/Applications/Xcode-beta.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
elif [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "=================================================="
echo "🚀 Starting viLilt Pro TestFlight Build Pipeline (VI AI INC)"
echo "=================================================="
echo "Using Xcode Developer Dir: ${DEVELOPER_DIR:-$(xcode-select -p)}"

# 1. Switch project to Pro configuration
python3 scripts/switch_target_tier.py pro

# 2. Clean previous build artifacts
rm -rf build/viLiltPro.xcarchive build/export_tf_pro
mkdir -p build

# 3. Build Archive
echo "📦 Creating Xcode Release Archive for viLilt Pro..."
xcodebuild archive \
  -project ViLilt.xcodeproj \
  -scheme ViLilt \
  -destination 'generic/platform=iOS' \
  -archivePath build/viLiltPro.xcarchive \
  -configuration Release \
  -allowProvisioningUpdates \
  CODE_SIGNING_ALLOWED=NO

echo "✅ Archive created successfully at build/viLiltPro.xcarchive"

# 4. Patch SDK version metadata for App Store Connect ingestion
echo "🛠️ Patching Xcode SDK metadata..."
python3 scripts/patch_archive_xcode_version.py build/viLiltPro.xcarchive

# 5. Upload to App Store Connect / TestFlight (VI AI INC)
echo "📤 Uploading archive to App Store Connect (VI AI INC)..."
AUTH_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_F7L5UST8LL.p8"
AUTH_KEY_ID="F7L5UST8LL"
AUTH_KEY_ISSUER="c1705e03-71a0-4e05-8ce7-61a583e57a06"

if [ -f "$AUTH_KEY_PATH" ]; then
  xcodebuild -exportArchive \
    -archivePath build/viLiltPro.xcarchive \
    -exportOptionsPlist ExportOptions_pro.plist \
    -exportPath build/export_tf_pro \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$AUTH_KEY_PATH" \
    -authenticationKeyID "$AUTH_KEY_ID" \
    -authenticationKeyIssuerID "$AUTH_KEY_ISSUER"
else
  xcodebuild -exportArchive \
    -archivePath build/viLiltPro.xcarchive \
    -exportOptionsPlist ExportOptions_pro.plist \
    -exportPath build/export_tf_pro \
    -allowProvisioningUpdates
fi

echo "=================================================="
echo "🎉 viLilt Pro TestFlight Build & Upload Complete!"
echo "=================================================="
