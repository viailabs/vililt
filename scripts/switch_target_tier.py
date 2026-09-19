import sys
import os
import re
import shutil

PBXPROJ = "ViLilt.xcodeproj/project.pbxproj"
MAIN_INFO_PLIST = "ViLilt/Info.plist"
ENTITLEMENTS = "ViLilt/ViLilt.entitlements"

def switch_tier(tier):
    if not os.path.exists(PBXPROJ):
        print(f"Error: {PBXPROJ} not found.")
        return False
    
    with open(PBXPROJ, 'r', encoding='utf-8') as f:
        content = f.read()

    if tier.lower() == "pro":
        team_id = "3PY896HD7X"
        main_bundle_id = "com.vi.vililt"
        app_name = "viLilt Pro"
        target_group = "group.com.vi.viclock"
    else:
        team_id = "43SKUJ8Z35"
        main_bundle_id = "org.viaiforgood.vililt"
        app_name = "viLilt"
        target_group = "group.org.viaiforgood.viclock"

    # Replace Team ID
    content = re.sub(r'DEVELOPMENT_TEAM = [0-9A-Z]{10};', f'DEVELOPMENT_TEAM = {team_id};', content)

    # Replace Bundle Identifier
    content = re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = (org\.viaiforgood\.vililt|com\.vi\.vililt);', f'PRODUCT_BUNDLE_IDENTIFIER = {main_bundle_id};', content)

    with open(PBXPROJ, 'w', encoding='utf-8') as f:
        f.write(content)

    # Update Main Info.plist CFBundleDisplayName
    if os.path.exists(MAIN_INFO_PLIST):
        with open(MAIN_INFO_PLIST, 'r', encoding='utf-8') as f:
            main_plist = f.read()
        if "<key>CFBundleDisplayName</key>" in main_plist:
            main_plist = re.sub(
                r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]+(</string>)',
                rf'\g<1>{app_name}\2',
                main_plist
            )
        else:
            main_plist = main_plist.replace("<dict>", f"<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>{app_name}</string>", 1)
        with open(MAIN_INFO_PLIST, 'w', encoding='utf-8') as f:
            f.write(main_plist)

    # Update Entitlements
    if os.path.exists(ENTITLEMENTS):
        with open(ENTITLEMENTS, 'r', encoding='utf-8') as f:
            ent_content = f.read()
        ent_content = re.sub(
            r'(<string>)group\.(org\.viaiforgood|com\.vi)\.viclock(</string>)',
            rf'\g<1>{target_group}\3',
            ent_content
        )
        with open(ENTITLEMENTS, 'w', encoding='utf-8') as f:
            f.write(ent_content)

    print(f"✅ Successfully switched viLilt to Tier: {tier.upper()} (Team: {team_id}, Bundle: {main_bundle_id}, Name: {app_name})")
    return True

if __name__ == "__main__":
    tier_arg = sys.argv[1] if len(sys.argv) > 1 else "impact"
    switch_tier(tier_arg)
