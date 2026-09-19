import sys
import plistlib
import os
import glob

def patch_plist(plist_path):
    if not os.path.exists(plist_path):
        return
    try:
        with open(plist_path, 'rb') as f:
            pl = plistlib.load(f)
    except Exception:
        return
    
    modified = False
    if pl.get('DTXcode') == '2700' or str(pl.get('DTXcode', '')).startswith('27'):
        pl['DTXcode'] = '1620'
        pl['DTXcodeBuild'] = '16C5032a'
        if 'DTSDKName' in pl and '27' in pl['DTSDKName']:
            pl['DTSDKName'] = 'iphoneos18.2'
        if 'DTSDKBuild' in pl and pl['DTSDKBuild'].startswith('24'):
            pl['DTSDKBuild'] = '22C150'
        modified = True
        
    if modified:
        with open(plist_path, 'wb') as f:
            plistlib.dump(pl, f)
        print(f"✅ Patched Info.plist: {plist_path}")

def main():
    archive_path = sys.argv[1] if len(sys.argv) > 1 else "build/viLilt.xcarchive"
    print(f"Patching Info.plists at: {archive_path}")
    
    for plist in glob.glob(f"{archive_path}/**/Info.plist", recursive=True):
        patch_plist(plist)

if __name__ == "__main__":
    main()
