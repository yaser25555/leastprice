#!/usr/bin/env python3
"""
LeastPrice Daily Offers Fetcher
This script simulates fetching the latest weekly flyers and offers 
from major Saudi stores (Panda, Othaim, Jarir, Extra, Nahdi, etc.)
and uploads them to the 'exclusive_deals' Firestore collection.
"""

import os
import json
import uuid
import argparse
from datetime import datetime, timedelta

import firebase_admin
from firebase_admin import credentials, firestore

# Constants
COLLECTION_NAME = "exclusive_deals"
DEFAULT_CREDENTIALS_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "leastprice-yaser-firebase-adminsdk-fbsvc-759edd3dbc.json"
)

# Simulated fresh daily offers
# In a real scenario, this data would be fetched using a web scraper (e.g., BeautifulSoup)
# from D4D Online, ClicFlyer, or directly from the stores' websites.
MOCK_DAILY_OFFERS = [
    {
        "store": "Panda",
        "title": "مهرجان بنده الأسبوعي - خصومات تصل لـ 50%",
        "imageUrl": "https://panda.com.sa/media/catalog/category/weekly_offers.jpg", # Placeholder
        "beforePrice": 200.0,
        "afterPrice": 100.0,
        "daysValid": 7
    },
    {
        "store": "Othaim",
        "title": "عروض الطازج من أسواق العثيم",
        "imageUrl": "https://www.othaimmarkets.com/media/weekly_flyer.jpg", # Placeholder
        "beforePrice": 150.0,
        "afterPrice": 90.0,
        "daysValid": 5
    },
    {
        "store": "Jarir",
        "title": "عروض جرير على أجهزة اللابتوب والجوالات",
        "imageUrl": "https://www.jarir.com/media/catalog/category/offers.jpg", # Placeholder
        "beforePrice": 4500.0,
        "afterPrice": 3999.0,
        "daysValid": 14
    },
    {
        "store": "Extra",
        "title": "التخفيضات الكبرى من إكسترا - أجهزة منزلية",
        "imageUrl": "https://www.extra.com/media/mega_sale.jpg", # Placeholder
        "beforePrice": 2500.0,
        "afterPrice": 1800.0,
        "daysValid": 10
    },
    {
        "store": "Nahdi",
        "title": "عروض النهدي: اشتري 1 والثاني مجاناً",
        "imageUrl": "https://www.nahdionline.com/media/bogo_offer.jpg", # Placeholder
        "beforePrice": 120.0,
        "afterPrice": 60.0,
        "daysValid": 7
    }
]

def initialize_firebase(credentials_path):
    if not os.path.exists(credentials_path):
        raise FileNotFoundError(f"Credentials file not found: {credentials_path}")
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
    
    return firestore.client()

def upload_offers_to_firestore(db, offers, dry_run=False):
    collection_ref = db.collection(COLLECTION_NAME)
    
    print(f"--- Starting to process {len(offers)} offers ---")
    
    success_count = 0
    for offer in offers:
        doc_id = f"offer_{offer['store'].lower()}_{datetime.now().strftime('%Y%m%d')}"
        expiry_date = datetime.now() + timedelta(days=offer['daysValid'])
        
        payload = {
            "title": offer['title'],
            "imageUrl": offer['imageUrl'],
            "beforePrice": offer['beforePrice'],
            "afterPrice": offer['afterPrice'],
            "expiry_date": expiry_date,
            "active": True,
            "createdByUid": "daily_offers_bot",
            "createdByEmail": "bot@leastprice.com",
            "lastUpdatedByUid": "daily_offers_bot",
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        
        if dry_run:
            print(f"[DRY RUN] Would add/update document '{doc_id}' in '{COLLECTION_NAME}':")
            print(json.dumps({k: str(v) for k, v in payload.items()}, ensure_ascii=False, indent=2))
        else:
            try:
                collection_ref.document(doc_id).set(payload, merge=True)
                print(f"[OK] Successfully uploaded: {offer['title']}")
                success_count += 1
            except Exception as e:
                print(f"[FAIL] Failed to upload {offer['title']}: {e}")
                
    if not dry_run:
        print(f"--- Finished! Successfully uploaded {success_count} offers to Firestore. ---")


def main():
    parser = argparse.ArgumentParser(description="Fetch daily offers and upload to Firestore")
    parser.add_argument("--credentials", type=str, default=DEFAULT_CREDENTIALS_PATH, 
                        help="Path to the Firebase Service Account JSON file")
    parser.add_argument("--dry-run", action="store_true", 
                        help="Print the payload without uploading to Firestore")
    
    args = parser.parse_args()
    
    print("[START] LeastPrice Daily Offers Bot Starting...")
    
    try:
        db = initialize_firebase(args.credentials)
    except Exception as e:
        print(f"[ERROR] Failed to connect to Firebase: {e}")
        return
    
    print("[SUCCESS] Connected to Firebase successfully.")
    upload_offers_to_firestore(db, MOCK_DAILY_OFFERS, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
