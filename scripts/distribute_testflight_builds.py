import time
import jwt
import requests
import os
import sys

def get_token(key_id, issuer_id, key_path):
    with open(key_path, 'r') as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        'iss': issuer_id,
        'exp': now + 20 * 60,
        'aud': 'appstoreconnect-v1'
    }
    headers = {
        'kid': key_id,
        'typ': 'JWT',
        'alg': 'ES256'
    }
    return jwt.encode(payload, private_key, algorithm='ES256', headers=headers)

def distribute_latest_builds(bundle_id, key_id, issuer_id, key_path, group_name="Dev"):
    key_path = os.path.expanduser(key_path)
    if not os.path.exists(key_path):
        print(f"❌ Key file not found: {key_path}")
        return False
        
    token = get_token(key_id, issuer_id, key_path)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    
    # 1. Get App ID
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}", headers=headers)
    if r.status_code != 200 or not r.json().get("data"):
        print(f"❌ App not found for {bundle_id}")
        return False
    app_id = r.json()["data"][0]["id"]
    
    # 2. Get Beta Group ID
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/betaGroups", headers=headers)
    groups = r.json().get("data", [])
    target_group = next((g for g in groups if g["attributes"]["name"] == group_name), None)
    if not target_group:
        print(f"❌ Beta group '{group_name}' not found for {bundle_id}")
        return False
    group_id = target_group["id"]
    
    # 3. Get Builds
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-version&limit=5", headers=headers)
    builds = r.json().get("data", [])
    if not builds:
        print(f"❌ No builds found for {bundle_id}")
        return False
        
    build_ids = [b["id"] for b in builds]
    build_versions = [b["attributes"]["version"] for b in builds]
    
    # 4. Associate Builds with Beta Group
    payload = {"data": [{"type": "builds", "id": bid} for bid in build_ids]}
    r = requests.post(f"https://api.appstoreconnect.apple.com/v1/betaGroups/{group_id}/relationships/builds", headers=headers, json=payload)
    if r.status_code in [200, 204]:
        print(f"✅ Distributed build(s) {build_versions} to TestFlight group '{group_name}'!")
        return True
    else:
        print(f"⚠️ Response {r.status_code}: {r.text}")
        return False

if __name__ == "__main__":
    print("🚀 Auto-distributing latest builds to TestFlight groups...")
    # Tier 1 (viaiforgood)
    distribute_latest_builds("org.viaiforgood.vililt", "HF628QL73G", "1952449e-2b2a-4b8b-bc2e-a51af7c12d19", "~/.appstoreconnect/private_keys/AuthKey_HF628QL73G.p8", "Dev")
    # Tier 2 (VI AI INC)
    distribute_latest_builds("com.vi.vililt", "F7L5UST8LL", "c1705e03-71a0-4e05-8ce7-61a583e57a06", "~/.appstoreconnect/private_keys/AuthKey_F7L5UST8LL.p8", "Dev")
