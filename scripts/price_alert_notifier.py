#!/usr/bin/env python3
"""
Checks favorites for price drops and sends OneSignal notifications.

Runs after daily_firestore_price_bot.py.
Requires env vars:
  GOOGLE_APPLICATION_CREDENTIALS
  ONESIGNAL_REST_API_KEY
  ONESIGNAL_APP_ID
"""

import os
import sys

import firebase_admin
import requests
from firebase_admin import credentials, firestore

ONESIGNAL_API = "https://onesignal.com/api/v1/notifications"
ONESIGNAL_APP_ID = os.getenv("ONESIGNAL_APP_ID", "715316fc-13d0-4fee-b0f8-860b4d38dee6")
ONESIGNAL_KEY = os.getenv("ONESIGNAL_REST_API_KEY", "")

FAVORITES_COLLECTION = os.getenv("FAVORITES_COLLECTION", "favorites")
PRODUCTS_COLLECTION = os.getenv("PRODUCTS_COLLECTION", "products")


def main():
    if not ONESIGNAL_KEY:
        print("SKIP: ONESIGNAL_REST_API_KEY not set.")
        return

    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    favorites_ref = db.collection(FAVORITES_COLLECTION)
    products_ref = db.collection(PRODUCTS_COLLECTION)

    # Read all favorites
    fav_docs = list(favorites_ref.stream())
    if not fav_docs:
        print("No favorites found.")
        return

    # Collect products that have been recently updated by the bot
    product_prices = {}
    for doc in products_ref.stream():
        data = doc.to_dict()
        url = data.get("productUrl", "")
        price = data.get("priceValue") or data.get("price")
        if url and price:
            product_prices[url.strip()] = float(price)

    notified = 0
    for doc in fav_docs:
        fav = doc.to_dict()
        product_url = (fav.get("productUrl") or "").strip()
        user_id = fav.get("userId", "")
        stored_price = float(fav.get("price") or 0)

        if not product_url or not user_id or stored_price <= 0:
            continue

        current_price = product_prices.get(product_url)
        if current_price is None:
            continue

        if current_price < stored_price:
            savings = stored_price - current_price
            _send_notification(
                user_id=user_id,
                title_ar="انخفاض السعر! 🎉",
                title_en="Price Dropped! 🎉",
                body_ar=f"انخفض سعر {fav.get('productTitle', '')} بمقدار {savings:.2f} SAR",
                body_en=f"Price of {fav.get('productTitle', '')} dropped by {savings:.2f} SAR",
            )
            notified += 1

    print(f"Price alerts sent: {notified}")


def _send_notification(user_id, title_ar, title_en, body_ar, body_en):
    payload = {
        "app_id": ONESIGNAL_APP_ID,
        "include_external_user_ids": [user_id],
        "headings": {"en": title_en, "ar": title_ar},
        "contents": {"en": body_en, "ar": body_ar},
    }
    try:
        resp = requests.post(
            ONESIGNAL_API,
            json=payload,
            headers={
                "Authorization": f"Basic {ONESIGNAL_KEY}",
                "Content-Type": "application/json",
            },
            timeout=15,
        )
        print(f"  → {user_id}: {resp.status_code}")
    except Exception as e:
        print(f"  → {user_id}: FAILED - {e}")


if __name__ == "__main__":
    main()
