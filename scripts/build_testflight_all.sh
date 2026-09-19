#!/usr/bin/env bash
set -e

# viLilt Master TestFlight Pipeline: Builds & Uploads BOTH Tier 1 (Impact) and Tier 2 (Pro)
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

echo "=================================================="
echo "🌟 VI LILT DUAL-TIER TESTFLIGHT BUILD & DEPLOY PIPELINE"
echo "=================================================="

# 1. Build and upload Tier 1 (viaiforgood - Nonprofit)
echo ""
echo "▶️ [1/3] Processing Tier 1: viLilt (viaiforgood)..."
bash scripts/build_testflight.sh

# 2. Build and upload Tier 2 (VI AI INC - Commercial Base)
echo ""
echo "▶️ [2/3] Processing Tier 2: viLilt Pro (VI AI INC)..."
bash scripts/build_testflight_pro.sh

# 3. Distribute both tiers to TestFlight groups
echo ""
echo "▶️ [3/3] Distributing builds to TestFlight tester groups..."
python3 scripts/distribute_testflight_builds.py || true

# 4. Restore to default Impact configuration
python3 scripts/switch_target_tier.py impact

echo ""
echo "=================================================="
echo "🎉 BOTH viLilt & viLilt Pro TestFlight Uploads Completed!"
echo "=================================================="
