#!/usr/bin/env python3
"""
LeastPrice Daily Offers Fetcher (Real Scraper)
This script scrapes real daily/weekly offers from D4D Online Saudi Arabia.
It filters for major supermarkets (Panda, Othaim, Carrefour, Lulu, Tamimi, Farm, etc.)
and uploads them to the 'exclusive_deals' Firestore collection.
"""

import os
import json
import re
from datetime import datetime, timedelta
import argparse

import requests
from bs4 import BeautifulSoup

import firebase_admin
from firebase_admin import credentials, firestore

# Constants
COLLECTION_NAME = "exclusive_deals"
DEFAULT_CREDENTIALS_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "leastprice-yaser-firebase-adminsdk-fbsvc-759edd3dbc.json"
)

# Target stores to filter
TARGET_STORES = [
    "بنده", "العثيم", "كارفور", "لولو", "التميمي", "المزرعة", "نستو", "الدانوب", "جرير", "اكسترا", "النهدي", "الدواء"
]

def initialize_firebase(credentials_path):
    if not os.path.exists(credentials_path):
        raise FileNotFoundError(f"Credentials file not found: {credentials_path}")
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
    
    return firestore.client()

def fetch_real_offers():
    print("[INFO] Fetching real offers from D4D Online (Riyadh/KSA)...")
    url = "https://www.d4donline.com/ar/saudi-arabia/riyadh/offers"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"[ERROR] Failed to fetch data: {e}")
        return []
        
    soup = BeautifulSoup(response.text, 'html.parser')
    banners = soup.select('.banner_offer')
    
    offers_list = []
    seen_titles = set()
    
    for b in banners:
        a_tag = b.find_parent('a')
        if not a_tag: continue
        
        full_title = a_tag.get('title', '').strip()
        link = a_tag.get('href', '')
        if not full_title or not link: continue
        
        # Check if it matches our target stores
        is_target = any(store in full_title for store in TARGET_STORES)
        if not is_target:
            continue
            
        # Clean title
        clean_title = re.sub(r'\s*المملكة العربية السعودية\s*Offers.*$', '', full_title).strip()
        if clean_title in seen_titles:
            continue
        seen_titles.add(clean_title)
        
        img_tag = b.select_one('img')
        img_url = ""
        if img_tag:
            img_url = img_tag.get('data-src') or img_tag.get('src') or ""
            
        # D4D links are relative
        if link.startswith('/'):
            link = "https://www.d4donline.com" + link
            
        # Set dummy prices since D4D flyers don't have individual prices on the cover
        offers_list.append({
            "title": clean_title,
            "imageUrl": img_url,
            "dealUrl": link,
            "beforePrice": 0.0,
            "afterPrice": 0.0,
            "daysValid": 7
        })
        
    print(f"[INFO] Found {len(offers_list)} target offers.")
    return offers_list

def upload_offers_to_firestore(db, offers, dry_run=False):
    collection_ref = db.collection(COLLECTION_NAME)
    success_count = 0
    
    for i, offer in enumerate(offers):
        doc_id = f"offer_real_{i}_{datetime.now().strftime('%Y%m%d')}"
        expiry_date = datetime.now() + timedelta(days=offer['daysValid'])
        
        payload = {
            "title": offer['title'],
            "imageUrl": offer['imageUrl'],
            "beforePrice": offer['beforePrice'],
            "afterPrice": offer['afterPrice'],
            "dealUrl": offer['dealUrl'],
            "expiry_date": expiry_date,
            "active": True,
            "createdByUid": "daily_offers_bot",
            "createdByEmail": "bot@leastprice.com",
            "lastUpdatedByUid": "daily_offers_bot",
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        
        if dry_run:
            print(f"[DRY RUN] {offer['title']} | URL: {offer['dealUrl']}")
        else:
            try:
                collection_ref.document(doc_id).set(payload, merge=True)
                print(f"[OK] Uploaded: {offer['title']}")
                success_count += 1
            except Exception as e:
                print(f"[FAIL] Failed to upload {offer['title']}: {e}")
                
    if not dry_run:
        print(f"--- Finished! Successfully uploaded {success_count} real offers. ---")

def main():
    parser = argparse.ArgumentParser(description="Fetch real daily offers and upload to Firestore")
    parser.add_argument("--credentials", type=str, default=DEFAULT_CREDENTIALS_PATH)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    
    print("[START] LeastPrice Real Offers Scraper Starting...")
    
    try:
        db = initialize_firebase(args.credentials)
        print("[SUCCESS] Connected to Firebase successfully.")
    except Exception as e:
        print(f"[ERROR] Failed to connect to Firebase: {e}")
        return
    
    offers = fetch_real_offers()
    if offers:
        upload_offers_to_firestore(db, offers, dry_run=args.dry_run)
    else:
        print("[WARN] No offers found.")

if __name__ == "__main__":
    main()
