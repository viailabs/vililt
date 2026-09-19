import time
import jwt
import requests
import os
import sys
import json

def get_token(key_id, issuer_id, key_path):
    with open(os.path.expanduser(key_path), 'r') as f:
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

def add_tester_to_group(headers, group_id, email, first_name="Tester", last_name="VI"):
    url = "https://api.appstoreconnect.apple.com/v1/betaTesters"
    
    # 1. Try to create / associate tester directly with the group
    payload = {
        "data": {
            "type": "betaTesters",
            "attributes": {
                "email": email,
                "firstName": first_name,
                "lastName": last_name
            },
            "relationships": {
                "betaGroups": {
                    "data": [
                        {
                            "type": "betaGroups",
                            "id": group_id
                        }
                    ]
                }
            }
        }
    }
    
    r = requests.post(url, headers=headers, json=payload)
    if r.status_code == 201:
        print(f"  ✅ Added & invited tester: {email}")
        return True
    elif r.status_code == 409:
        # Tester already exists on account, query their ID and link to group
        r_find = requests.get(f"{url}?filter[email]={email}", headers=headers)
        if r_find.status_code == 200 and r_find.json().get("data"):
            tester_id = r_find.json()["data"][0]["id"]
            link_url = f"https://api.appstoreconnect.apple.com/v1/betaGroups/{group_id}/relationships/betaTesters"
            link_payload = {
                "data": [
                    {
                        "type": "betaTesters",
                        "id": tester_id
                    }
                ]
            }
            r_link = requests.post(link_url, headers=headers, json=link_payload)
            if r_link.status_code in [200, 204]:
                print(f"  ✅ Successfully linked existing tester: {email} (ID: {tester_id})")
                return True
            else:
                print(f"  ℹ️ Tester {email} link status ({r_link.status_code}): {r_link.text}")
                return True
    print(f"  ⚠️ Tester {email} status ({r.status_code}): {r.text}")
    return False

def configure_testflight(account_name, bundle_id, key_id, issuer_id, key_path, testers_list):
    print(f"\n==================================================")
    print(f"🔧 Configuring TestFlight for {bundle_id} ({account_name})")
    print(f"==================================================")
    
    token = get_token(key_id, issuer_id, key_path)
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    
    # 1. Get App
    r = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}", headers=headers)
    if r.status_code != 200 or not r.json().get("data"):
        print(f"❌ App not found for {bundle_id}")
        return
    app = r.json()["data"][0]
    app_id = app["id"]
    
    # 2. Get Beta Groups (both Internal Team & Dev)
    r_groups = requests.get(f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/betaGroups", headers=headers)
    groups = r_groups.json().get("data", [])
    
    # 3. Get Builds
    r_builds = requests.get(f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&limit=5", headers=headers)
    builds = r_builds.json().get("data", [])
    build_payload = {"data": [{"type": "builds", "id": b["id"]} for b in builds]} if builds else None
    build_versions = [b["attributes"]["version"] for b in builds] if builds else []
    print(f"📦 Found builds on account: {build_versions}")

    for g in groups:
        g_name = g["attributes"]["name"]
        g_id = g["id"]
        is_internal = g["attributes"].get("isInternalGroup", False)
        print(f"\n👥 Configuring Group: '{g_name}' (ID: {g_id}, isInternal: {is_internal})")
        
        # Attach builds
        if build_payload:
            r_badd = requests.post(f"https://api.appstoreconnect.apple.com/v1/betaGroups/{g_id}/relationships/builds", headers=headers, json=build_payload)
            if r_badd.status_code in [200, 204]:
                print(f"  ✅ Attached builds {build_versions} to group '{g_name}'")
            else:
                print(f"  ℹ️ Build attachment status ({r_badd.status_code}): {r_badd.text}")
                
        # Add testers
        for t in testers_list:
            add_tester_to_group(headers, g_id, t["email"], t["firstName"], t["lastName"])

def main():
    tier1_testers = [
        {"email": "huomingxu@gmail.com", "firstName": "Michael", "lastName": "Huo"},
        {"email": "developer@viaiforgood.org", "firstName": "Developer", "lastName": "viaiforgood"},
        {"email": "gaoshuang@gmail.com", "firstName": "Susan", "lastName": "Gao"}
    ]
    
    tier2_testers = [
        {"email": "huomingxu@gmail.com", "firstName": "Michael", "lastName": "Huo"},
        {"email": "developer@viai.ai", "firstName": "Developer", "lastName": "VI AI"},
        {"email": "developer@viaifoundation.org", "firstName": "Developer", "lastName": "Foundation"},
        {"email": "michael@viai.ai", "firstName": "Michael", "lastName": "Huo"},
        {"email": "gaoshuang@gmail.com", "firstName": "Susan", "lastName": "Gao"}
    ]
    
    # Tier 1 (viaiforgood)
    configure_testflight(
        account_name="viaiforgood (Nonprofit)",
        bundle_id="org.viaiforgood.vililt",
        key_id="HF628QL73G",
        issuer_id="1952449e-2b2a-4b8b-bc2e-a51af7c12d19",
        key_path="~/.appstoreconnect/private_keys/AuthKey_HF628QL73G.p8",
        testers_list=tier1_testers
    )
    
    # Tier 2 (VI AI INC)
    configure_testflight(
        account_name="VI AI INC (Commercial)",
        bundle_id="com.vi.vililt",
        key_id="F7L5UST8LL",
        issuer_id="c1705e03-71a0-4e05-8ce7-61a583e57a06",
        key_path="~/.appstoreconnect/private_keys/AuthKey_F7L5UST8LL.p8",
        testers_list=tier2_testers
    )

if __name__ == "__main__":
    main()
