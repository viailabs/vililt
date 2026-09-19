import time
import jwt
import requests
import os
import sys
import json

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

def register_bundle_id(headers, identifier, name, platform="UNIVERSAL"):
    url = "https://api.appstoreconnect.apple.com/v1/bundleIds"
    
    # Check if already exists
    r_check = requests.get(f"{url}?filter[identifier]={identifier}", headers=headers)
    if r_check.status_code == 200:
        existing = r_check.json().get("data", [])
        if existing:
            bundle_id_obj = existing[0]
            print(f"  ℹ️ Bundle ID already exists: {identifier} (ID: {bundle_id_obj['id']})")
            return bundle_id_obj["id"]
            
    payload = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": identifier,
                "name": name,
                "platform": platform
            }
        }
    }
    
    r = requests.post(url, headers=headers, json=payload)
    if r.status_code == 201:
        bundle_id_obj = r.json()["data"]
        print(f"  ✅ Successfully registered Bundle ID: {identifier} (ID: {bundle_id_obj['id']})")
        return bundle_id_obj["id"]
    else:
        if platform == "UNIVERSAL":
            return register_bundle_id(headers, identifier, name, platform="IOS")
        print(f"  ❌ Failed to register Bundle ID {identifier}: {r.status_code} {r.text}")
        return None

def create_app(headers, bundle_id_resource_id, app_name, sku, primary_locale="en-US"):
    url = "https://api.appstoreconnect.apple.com/v1/apps"
    
    # Check if app already exists
    r_check = requests.get(f"{url}?filter[bundleId]={bundle_id_resource_id}", headers=headers)
    if r_check.status_code == 200:
        existing = r_check.json().get("data", [])
        if existing:
            app_obj = existing[0]
            print(f"  ℹ️ App already exists on App Store Connect: {app_obj['attributes']['name']} (ID: {app_obj['id']})")
            return app_obj
            
    payload = {
        "data": {
            "type": "apps",
            "attributes": {
                "name": app_name,
                "primaryLocale": primary_locale,
                "sku": sku
            },
            "relationships": {
                "bundleId": {
                    "data": {
                        "type": "bundleIds",
                        "id": bundle_id_resource_id
                    }
                }
            }
        }
    }
    
    r = requests.post(url, headers=headers, json=payload)
    if r.status_code == 201:
        app_obj = r.json()["data"]
        print(f"  🎉 Successfully created App '{app_name}' on App Store Connect! (ID: {app_obj['id']}, SKU: {sku})")
        return app_obj
    else:
        print(f"  ❌ Failed to create App '{app_name}': {r.status_code} {r.text}")
        return None

def main():
    print("==================================================")
    print("🚀 App Store Connect: Creating viLilt Apps")
    print("==================================================")
    
    # --- Account 1: viaiforgood (Nonprofit) ---
    print("\n📦 [1/2] Processing Tier 1: viLilt (Nonprofit - viaiforgood)...")
    key_path_1 = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_HF628QL73G.p8")
    token1 = get_token("HF628QL73G", "1952449e-2b2a-4b8b-bc2e-a51af7c12d19", key_path_1)
    headers1 = {"Authorization": f"Bearer {token1}", "Content-Type": "application/json"}
    
    bundle_id_1 = register_bundle_id(headers1, "org.viaiforgood.vililt", "viLilt", "UNIVERSAL")
    if bundle_id_1:
        app1 = create_app(headers1, bundle_id_1, "viLilt", "vililt_ios_impact", "en-US")
    
    # --- Account 2: VI AI INC (Commercial) ---
    print("\n📦 [2/2] Processing Tier 2: viLilt Pro (Commercial - VI AI INC)...")
    key_path_2 = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_F7L5UST8LL.p8")
    token2 = get_token("F7L5UST8LL", "c1705e03-71a0-4e05-8ce7-61a583e57a06", key_path_2)
    headers2 = {"Authorization": f"Bearer {token2}", "Content-Type": "application/json"}
    
    bundle_id_2 = register_bundle_id(headers2, "com.vi.vililt", "viLilt Pro", "UNIVERSAL")
    if bundle_id_2:
        app2 = create_app(headers2, bundle_id_2, "viLilt Pro", "vililt_pro_ios", "en-US")

    print("\n==================================================")
    print("🎉 App Creation Pipeline Finished!")
    print("==================================================")

if __name__ == "__main__":
    main()
