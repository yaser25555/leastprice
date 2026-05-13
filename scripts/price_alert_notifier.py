#!/usr/bin/env python3
"""
Checks price_alerts for price drops and sends OneSignal notifications.

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

PRICE_ALERTS_COLLECTION = os.getenv("PRICE_ALERTS_COLLECTION", "price_alerts")
PRODUCTS_COLLECTION = os.getenv("PRODUCTS_COLLECTION", "products")


def main():
    if not ONESIGNAL_KEY:
        print("SKIP: ONESIGNAL_REST_API_KEY not set.")
        return

    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    alerts_ref = db.collection(PRICE_ALERTS_COLLECTION)
    products_ref = db.collection(PRODUCTS_COLLECTION)

    # Read all active price alerts
    alert_docs = list(alerts_ref.where("active", "==", True).stream())
    if not alert_docs:
        print("No active price alerts found.")
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
    for doc in alert_docs:
        alert = doc.to_dict()
        product_url = (alert.get("productUrl") or "").strip()
        user_id = alert.get("userId", "")
        target_price = float(alert.get("targetPrice") or 0)

        if not product_url or not user_id or target_price <= 0:
            continue

        current_price = product_prices.get(product_url)
        if current_price is None:
            continue

        # Update currentPrice on the alert document
        doc_ref = alerts_ref.document(doc.id)
        doc_ref.update({"currentPrice": current_price})

        if current_price <= target_price:
            savings = target_price - current_price
            _send_notification(
                user_id=user_id,
                title_ar="انخفاض السعر! 🎉",
                title_en="Price Dropped! 🎉",
                body_ar=f"وصل سعر {alert.get('productTitle', '')} إلى {current_price:.2f} SAR",
                body_en=f"Price of {alert.get('productTitle', '')} is now {current_price:.2f} SAR",
            )
            notified += 1
            # Deactivate the alert after notifying
            doc_ref.update({"active": False})

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
        print(f"  -> {user_id}: {resp.status_code}")
    except Exception as e:
        print(f"  -> {user_id}: FAILED - {e}")


if __name__ == "__main__":
    main()
