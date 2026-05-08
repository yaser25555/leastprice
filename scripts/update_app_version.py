import os
import yaml
import firebase_admin
from firebase_admin import credentials, firestore
import argparse

def update_version_in_firestore(version=None, update_url=None, force_update=False):
    # 1. Load version from pubspec if not provided
    if not version:
        with open('pubspec.yaml', 'r') as f:
            pubspec = yaml.safe_load(f)
            version = pubspec.get('version', '1.0.0').split('+')[0]
    
    print(f"🚀 Updating App Version to: {version}")

    # 2. Initialize Firebase
    # Assumes GOOGLE_APPLICATION_CREDENTIALS is set or service account exists
    try:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
    except Exception:
        # Fallback for local testing if path is known
        service_account_path = 'leastprice-yaser-firebase-adminsdk-fbsvc-759edd3dbc.json'
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            print("❌ Error: Firebase credentials not found.")
            return

    db = firestore.client()

    # 3. Update Firestore
    doc_ref = db.collection('config').document('app_info')
    
    data = {
        'latest_version': version,
        'force_update': force_update,
        'message_ar': "تحديث جديد متوفر الآن يتضمن تحسينات هامة لجلب الأسعار والمتاجر.",
        'message_en': "A new update is available with improved price fetching and store support.",
    }

    if update_url:
        data['update_url'] = update_url
    
    doc_ref.set(data, merge=True)
    print("✅ Firestore updated successfully!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update App Version in Firestore')
    parser.add_argument('--version', type=str, help='New version string')
    parser.add_argument('--url', type=str, help='Download URL for the new APK')
    parser.add_argument('--force', action='store_true', help='Force users to update')
    
    args = parser.parse_with_known_args()[0]
    update_version_in_firestore(version=args.version, update_url=args.url, force_update=args.force)
