#!/usr/bin/env python3
"""
Daily Firestore automation for LeastPrice.

Required environment variables:
  GOOGLE_APPLICATION_CREDENTIALS=/abs/path/service-account.json
  SERPER_API_KEY=...              # when SEARCH_PROVIDER=serper

Optional environment variables:
  FIREBASE_PROJECT_ID=leastprice-yaser
  SEARCH_PROVIDER=serper|tavily
  TAVILY_API_KEY=...
  PRODUCTS_COLLECTION=products
  POPULAR_PRODUCTS_COLLECTION=popular_products
  SEARCH_REQUESTS_COLLECTION=search_requests
  SYSTEM_HEALTH_COLLECTION=system_health
  SEARCH_REQUEST_LIMIT=20
  AFFILIATE_TAG=myid-21
  DRY_RUN=true
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Sequence, Tuple
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

import firebase_admin
import requests
from firebase_admin import credentials, firestore


SERPER_ENDPOINT = "https://google.serper.dev/search"
TAVILY_ENDPOINT = "https://api.tavily.com/search"
DEFAULT_PRODUCTS_COLLECTION = os.getenv("PRODUCTS_COLLECTION", "products").strip() or "products"
DEFAULT_POPULAR_PRODUCTS_COLLECTION = (
    os.getenv("POPULAR_PRODUCTS_COLLECTION", "popular_products").strip() or "popular_products"
)
DEFAULT_SEARCH_REQUESTS_COLLECTION = (
    os.getenv("SEARCH_REQUESTS_COLLECTION", "search_requests").strip() or "search_requests"
)
DEFAULT_SYSTEM_HEALTH_COLLECTION = (
    os.getenv("SYSTEM_HEALTH_COLLECTION", "system_health").strip() or "system_health"
)
DEFAULT_REQUEST_LIMIT = int(os.getenv("SEARCH_REQUEST_LIMIT", "20"))
DEFAULT_TOP_DEMAND_LIMIT = int(os.getenv("TOP_DEMAND_LIMIT", "12"))
DEFAULT_MIN_REQUEST_COUNT = int(os.getenv("MIN_REQUEST_COUNT", "2"))
AFFILIATE_TAG = os.getenv("AFFILIATE_TAG", "myid-21").strip() or "myid-21"
SEARCH_PROVIDER = os.getenv("SEARCH_PROVIDER", "serper").strip().lower() or "serper"
SEARCH_TIMEOUT_SECONDS = 30
ORIGINAL_ON_SALE_TAG = "\u0627\u0644\u0645\u0646\u062a\u062c \u0627\u0644\u0623\u0635\u0644\u064a \u0639\u0644\u064a\u0647 \u0639\u0631\u0636 \u062d\u0627\u0644\u064a\u0627\u064b"
TOP_SEARCH_DEMAND_TAG = "\u0627\u0644\u0623\u0643\u062b\u0631 \u0637\u0644\u0628\u0627\u064b"
SEARCH_DEMAND_SYNC_TAG = "\u062a\u062d\u062f\u064a\u062b \u0645\u0628\u0646\u064a \u0639\u0644\u0649 \u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0628\u062d\u062b"

EXPENSIVE_HOSTS = ("amazon.sa", "www.amazon.sa", "noon.com", "www.noon.com")
ALTERNATIVE_HOSTS = (
    "amazon.sa",
    "www.amazon.sa",
    "noon.com",
    "www.noon.com",
    "nahdionline.com",
    "www.nahdionline.com",
    "al-dawaa.com",
    "www.al-dawaa.com",
    "hungerstation.com",
    "www.hungerstation.com",
    "jahez.net",
    "www.jahez.net",
    "mrsool.co",
    "www.mrsool.co",
)

CATEGORY_LABELS = {
    "all": "\u0627\u0644\u0643\u0644",
    "coffee": "\u0642\u0647\u0648\u0629",
    "roasters": "\u0645\u062d\u0627\u0645\u0635",
    "restaurants": "\u0645\u0637\u0627\u0639\u0645",
    "perfumes": "\u0639\u0637\u0648\u0631",
    "cosmetics": "\u062a\u062c\u0645\u064a\u0644",
    "pharmacy": "\u0635\u064a\u062f\u0644\u064a\u0629",
    "detergents": "\u0645\u0646\u0638\u0641\u0627\u062a",
    "dairy": "\u0623\u0644\u0628\u0627\u0646",
    "canned": "\u0645\u0639\u0644\u0628\u0627\u062a",
    "tea": "\u0634\u0627\u064a",
    "juice": "\u0639\u0635\u064a\u0631",
}

CATEGORY_KEYWORDS = {
    "coffee": ("coffee", "\u0642\u0647\u0648\u0647", "\u0642\u0647\u0648\u0629", "latte", "espresso"),
    "roasters": (
        "roaster",
        "roastery",
        "\u0645\u062d\u0645\u0635",
        "\u0645\u062d\u0627\u0645\u0635",
        "\u0628\u0646",
        "\u062d\u0628\u0648\u0628",
    ),
    "restaurants": (
        "burger",
        "meal",
        "restaurant",
        "\u0645\u0637\u0639\u0645",
        "\u0648\u062c\u0628\u0647",
        "\u0648\u062c\u0628\u0629",
        "\u0628\u0631\u062c\u0631",
    ),
    "perfumes": (
        "perfume",
        "parfum",
        "fragrance",
        "\u0639\u0637\u0631",
        "\u0631\u0627\u0626\u062d\u0647",
        "\u0631\u0627\u0626\u062d\u0629",
    ),
    "cosmetics": (
        "serum",
        "makeup",
        "beauty",
        "\u062a\u062c\u0645\u064a\u0644",
        "\u0633\u064a\u0631\u0648\u0645",
        "\u0645\u0643\u064a\u0627\u062c",
        "\u0643\u0631\u064a\u0645",
    ),
    "pharmacy": (
        "pharmacy",
        "cream",
        "medicine",
        "\u0635\u064a\u062f\u0644\u064a\u0647",
        "\u0635\u064a\u062f\u0644\u064a\u0629",
        "\u0645\u0631\u0637\u0628",
        "\u062f\u0648\u0627\u0621",
    ),
    "detergents": ("cleaner", "detergent", "\u0645\u0646\u0638\u0641", "\u062a\u0646\u0638\u064a\u0641"),
    "dairy": ("\u0623\u0644\u0628\u0627\u0646", "\u0627\u0644\u0628\u0627\u0646", "\u062d\u0644\u064a\u0628", "\u062c\u0628\u0646\u0647", "\u062c\u0628\u0646\u0629"),
    "canned": ("\u0645\u0639\u0644\u0628", "\u0645\u0639\u0644\u0628\u0627\u062a", "\u0645\u0639\u062c\u0648\u0646", "canned", "paste"),
    "tea": ("tea", "\u0634\u0627\u064a"),
    "juice": ("juice", "\u0639\u0635\u064a\u0631"),
}

PRICE_PATTERNS = (
    re.compile(r"(?:SAR|\u0631\.?\s?\u0633|\u0631\u064a\u0627\u0644)\s*([0-9]+(?:\.[0-9]{1,2})?)", re.I),
    re.compile(r"([0-9]+(?:\.[0-9]{1,2})?)\s*(?:SAR|\u0631\.?\s?\u0633|\u0631\u064a\u0627\u0644)", re.I),
)


@dataclass(frozen=True)
class SearchHit:
    title: str
    link: str
    snippet: str
    price: Optional[float] = None

    @property
    def host(self) -> str:
        return urlparse(self.link).netloc.lower()


@dataclass(frozen=True)
class CatalogCandidate:
    name: str
    price: float
    link: str
    host_label: str
    category_id: str
    category_label: str
    detail: Optional[str]


def main() -> int:
    arguments = parse_arguments()
    dry_run = arguments.dry_run or os.getenv("DRY_RUN", "").strip().lower() in {"1", "true", "yes"}

    database = initialize_firestore(
        credentials_path=arguments.credentials_path,
        project_id=arguments.project_id,
    )
    search_client = SearchClient.from_environment(arguments.provider)

    products_collection = database.collection(arguments.products_collection)
    popular_products_collection = database.collection(arguments.popular_products_collection)
    search_requests_collection = database.collection(arguments.search_requests_collection)

    stats = {
        "popular_checked": 0,
        "popular_created": 0,
        "popular_updated": 0,
        "popular_skipped": 0,
        "popular_needs_review": 0,
        "products_checked": 0,
        "products_updated": 0,
        "products_flagged": 0,
        "requests_checked": 0,
        "requests_fulfilled": 0,
        "requests_skipped": 0,
        "requests_need_review": 0,
        "demand_checked": 0,
        "demand_promoted": 0,
        "demand_updated": 0,
        "demand_skipped": 0,
        "demand_missing_product": 0,
    }

    product_snapshots = list(products_collection.stream())
    existing_products = [snapshot.to_dict() | {"documentId": snapshot.id} for snapshot in product_snapshots]
    existing_signatures = {
        build_product_signature(product)
        for product in existing_products
        if build_product_signature(product)
    }

    popular_snapshots = list(popular_products_collection.stream())
    popular_snapshots.sort(
        key=lambda snapshot: -safe_int((snapshot.to_dict() or {}).get("priority")),
    )

    for snapshot in popular_snapshots:
        stats["popular_checked"] += 1
        result = process_popular_product(
            database=database,
            snapshot=snapshot,
            search_client=search_client,
            existing_products=existing_products,
            existing_signatures=existing_signatures,
            dry_run=dry_run,
            products_collection_name=arguments.products_collection,
        )
        stats[result] += 1

    product_snapshots = list(products_collection.stream())
    existing_products = [snapshot.to_dict() | {"documentId": snapshot.id} for snapshot in product_snapshots]

    for snapshot in product_snapshots:
        stats["products_checked"] += 1
        if refresh_product_document(
            snapshot=snapshot,
            search_client=search_client,
            dry_run=dry_run,
        ):
            stats["products_updated"] += 1

        updated_product = snapshot.to_dict() or {}
        updated_tags = updated_product.get("tags") or []
        if isinstance(updated_tags, list) and ORIGINAL_ON_SALE_TAG in updated_tags:
            stats["products_flagged"] += 1

    pending_requests = list(search_requests_collection.stream())
    pending_requests.sort(
        key=lambda snapshot: -safe_int((snapshot.to_dict() or {}).get("requestCount")),
    )

    for snapshot in pending_requests[: arguments.search_request_limit]:
        stats["requests_checked"] += 1
        result = process_search_request(
            database=database,
            snapshot=snapshot,
            search_client=search_client,
            existing_products=existing_products,
            existing_signatures=existing_signatures,
            dry_run=dry_run,
            products_collection_name=arguments.products_collection,
        )
        stats[result] += 1

    refreshed_request_snapshots = list(search_requests_collection.stream())
    refreshed_request_snapshots.sort(
        key=build_search_request_rank,
        reverse=True,
    )

    demand_stats = sync_top_search_demand_to_popular_products(
        database=database,
        snapshots=refreshed_request_snapshots,
        existing_products=existing_products,
        dry_run=dry_run,
        popular_products_collection_name=arguments.popular_products_collection,
        top_limit=arguments.top_demand_limit,
        min_request_count=arguments.min_request_count,
    )
    for key, value in demand_stats.items():
        stats[key] += value

    write_system_health(
        database=database,
        collection_name=arguments.system_health_collection,
        stats=stats,
        provider=search_client.provider,
        project_id=arguments.project_id,
        products_collection_name=arguments.products_collection,
        popular_products_collection_name=arguments.popular_products_collection,
        search_requests_collection_name=arguments.search_requests_collection,
        dry_run=dry_run,
    )

    print("")
    print("LeastPrice daily automation summary")
    print("----------------------------------")
    for key, value in stats.items():
        print(f"{key}: {value}")

    return 0


def write_system_health(
    *,
    database: firestore.Client,
    collection_name: str,
    stats: Dict[str, int],
    provider: str,
    project_id: str,
    products_collection_name: str,
    popular_products_collection_name: str,
    search_requests_collection_name: str,
    dry_run: bool,
) -> None:
    payload: Dict[str, Any] = {
        "service": "daily_price_bot",
        "status": "success",
        "message": "تم آخر تحديث ناجح بواسطة الروبوت اليومي.",
        "provider": provider,
        "projectId": project_id or "",
        "updatedBy": "github_actions" if os.getenv("GITHUB_ACTIONS") == "true" else "manual",
        "lastRunAt": firestore.SERVER_TIMESTAMP,
        "lastSuccessAt": firestore.SERVER_TIMESTAMP,
        "collections": {
            "products": products_collection_name,
            "popularProducts": popular_products_collection_name,
            "searchRequests": search_requests_collection_name,
        },
        "stats": stats,
    }

    document = database.collection(collection_name).document("daily_price_bot")
    if dry_run:
        print(f"[DRY RUN] would update system health: {payload}")
        return

    document.set(payload, merge=True)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Daily Firestore automation for LeastPrice.")
    parser.add_argument(
        "--credentials-path",
        default=os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip(),
        help="Path to the Firebase service-account JSON file.",
    )
    parser.add_argument(
        "--project-id",
        default=os.getenv("FIREBASE_PROJECT_ID", "").strip(),
        help="Optional Firebase project id override.",
    )
    parser.add_argument(
        "--provider",
        default=SEARCH_PROVIDER,
        choices=("serper", "tavily"),
        help="Search provider to use for daily discovery.",
    )
    parser.add_argument(
        "--products-collection",
        default=DEFAULT_PRODUCTS_COLLECTION,
        help="Firestore collection name for products.",
    )
    parser.add_argument(
        "--popular-products-collection",
        default=DEFAULT_POPULAR_PRODUCTS_COLLECTION,
        help="Firestore collection name for popular product templates.",
    )
    parser.add_argument(
        "--search-requests-collection",
        default=DEFAULT_SEARCH_REQUESTS_COLLECTION,
        help="Firestore collection name for queued user searches.",
    )
    parser.add_argument(
        "--system-health-collection",
        default=DEFAULT_SYSTEM_HEALTH_COLLECTION,
        help="Firestore collection name for automation health logs.",
    )
    parser.add_argument(
        "--search-request-limit",
        type=int,
        default=DEFAULT_REQUEST_LIMIT,
        help="Maximum queued user searches to process in one run.",
    )
    parser.add_argument(
        "--top-demand-limit",
        type=int,
        default=DEFAULT_TOP_DEMAND_LIMIT,
        help="Maximum high-demand searches to sync into popular_products per run.",
    )
    parser.add_argument(
        "--min-request-count",
        type=int,
        default=DEFAULT_MIN_REQUEST_COUNT,
        help="Minimum number of repeated searches required before promoting a term.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print intended updates without writing to Firestore.",
    )

    args = parser.parse_args()
    if not args.credentials_path:
        parser.error("Missing --credentials-path or GOOGLE_APPLICATION_CREDENTIALS.")
    return args


def initialize_firestore(*, credentials_path: str, project_id: str) -> firestore.Client:
    if not os.path.exists(credentials_path):
        raise FileNotFoundError(f"Service-account file not found: {credentials_path}")

    if not firebase_admin._apps:
        credential = credentials.Certificate(credentials_path)
        options = {"projectId": project_id} if project_id else None
        firebase_admin.initialize_app(credential, options=options)

    return firestore.client()


class SearchClient:
    def __init__(self, provider: str, api_key: str) -> None:
        self.provider = provider
        self.api_key = api_key

    @classmethod
    def from_environment(cls, provider: str) -> "SearchClient":
        if provider == "serper":
            api_key = os.getenv("SERPER_API_KEY", "").strip()
            if not api_key:
                raise RuntimeError("SERPER_API_KEY is required when SEARCH_PROVIDER=serper.")
            return cls(provider=provider, api_key=api_key)

        api_key = os.getenv("TAVILY_API_KEY", "").strip()
        if not api_key:
            raise RuntimeError("TAVILY_API_KEY is required when SEARCH_PROVIDER=tavily.")
        return cls(provider=provider, api_key=api_key)

    def search(self, query: str) -> List[SearchHit]:
        if self.provider == "serper":
            return self._search_serper(query)
        return self._search_tavily(query)

    def _search_serper(self, query: str) -> List[SearchHit]:
        response = requests.post(
            "https://google.serper.dev/shopping",
            headers={
                "Content-Type": "application/json",
                "X-API-KEY": self.api_key,
            },
            json={
                "q": query,
                "gl": "sa",
                "hl": "ar",
                "num": 5,
            },
            timeout=SEARCH_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        payload = response.json()
        shopping = payload.get("shopping")
        if not isinstance(shopping, list):
            # Fallback to organic if shopping is empty or missing
            organic = payload.get("organic")
            if not isinstance(organic, list):
                return []
            return [
                SearchHit(
                    title=safe_string(item.get("title")),
                    link=safe_string(item.get("link")),
                    snippet=safe_string(item.get("snippet")),
                )
                for item in organic
                if safe_string(item.get("link"))
            ]

        hits = []
        for item in shopping:
            link = safe_string(item.get("link"))
            if not link:
                continue
            
            price_text = safe_string(item.get("price"))
            parsed_price = None
            if price_text:
                for pattern in PRICE_PATTERNS:
                    match = pattern.search(price_text)
                    if match:
                        parsed_price = safe_float(match.group(1))
                        break

            hits.append(
                SearchHit(
                    title=safe_string(item.get("title")),
                    link=link,
                    snippet=price_text,  # store price text as snippet for fallback
                    price=parsed_price,
                )
            )
        return hits

    def _search_tavily(self, query: str) -> List[SearchHit]:
        response = requests.post(
            TAVILY_ENDPOINT,
            json={
                "api_key": self.api_key,
                "query": query,
                "search_depth": "advanced",
                "max_results": 5,
                "include_answer": False,
            },
            timeout=SEARCH_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
        payload = response.json()
        results = payload.get("results")
        if not isinstance(results, list):
            return []

        return [
            SearchHit(
                title=safe_string(item.get("title")),
                link=safe_string(item.get("url")),
                snippet=safe_string(item.get("content")),
            )
            for item in results
            if safe_string(item.get("url"))
        ]


def refresh_product_document(
    *,
    snapshot: Any,
    search_client: SearchClient,
    dry_run: bool,
) -> bool:
    payload = snapshot.to_dict() or {}
    expensive_name = safe_string(payload.get("expensiveName"))
    alternative_name = safe_string(payload.get("alternativeName"))
    if not expensive_name or not alternative_name:
        return False

    expensive_hit = choose_best_result(
        search_client.search(build_expensive_query(expensive_name)),
        preferred_hosts=EXPENSIVE_HOSTS,
    )
    alternative_hit = choose_best_result(
        search_client.search(build_alternative_query(alternative_name)),
        preferred_hosts=ALTERNATIVE_HOSTS,
        require_preferred_host=True,
    )

    current_expensive_price = safe_float(payload.get("expensivePrice"))
    current_alternative_price = safe_float(payload.get("alternativePrice"))

    next_expensive_price = extract_price_from_hit(expensive_hit) or current_expensive_price
    next_alternative_price = extract_price_from_hit(alternative_hit) or current_alternative_price
    next_buy_url = payload.get("buyUrl") or ""
    if alternative_hit is not None and is_supported_store_link(alternative_hit.link):
        next_buy_url = attach_affiliate_tag(alternative_hit.link)
    else:
        next_buy_url = attach_affiliate_tag(safe_string(next_buy_url))

    next_tags = sync_offer_tags(
        payload.get("tags"),
        expensive_price=next_expensive_price,
        alternative_price=next_alternative_price,
    )

    updates: Dict[str, Any] = {}
    if prices_different(current_expensive_price, next_expensive_price):
        updates["expensivePrice"] = round(next_expensive_price, 2)
    if prices_different(current_alternative_price, next_alternative_price):
        updates["alternativePrice"] = round(next_alternative_price, 2)
    if not safe_bool(payload.get("is_automated"), default=False):
        updates["is_automated"] = True
    if safe_string(payload.get("buyUrl")) != next_buy_url and next_buy_url:
        updates["buyUrl"] = next_buy_url
    if safe_string_list(payload.get("tags")) != next_tags:
        updates["tags"] = next_tags

    if not updates:
        return False

    updates["updatedAt"] = firestore.SERVER_TIMESTAMP
    updates["priceMonitor"] = {
        "provider": search_client.provider,
        "checkedAt": firestore.SERVER_TIMESTAMP,
        "expensiveSourceUrl": expensive_hit.link if expensive_hit else None,
        "alternativeSourceUrl": alternative_hit.link if alternative_hit else None,
    }

    if dry_run:
        print(f"[DRY RUN] would update product {snapshot.id}: {updates}")
        return True

    snapshot.reference.set(updates, merge=True)
    return True


def process_popular_product(
    *,
    database: firestore.Client,
    snapshot: Any,
    search_client: SearchClient,
    existing_products: List[Dict[str, Any]],
    existing_signatures: set[str],
    dry_run: bool,
    products_collection_name: str,
) -> str:
    payload = snapshot.to_dict() or {}
    if not safe_bool(payload.get("active"), default=True):
        return "popular_skipped"

    generated = build_product_from_popular_item(
        search_client=search_client,
        payload=payload,
    )
    if generated is None:
        update_popular_status(
            snapshot=snapshot,
            status="needs_review",
            notes="Popular product did not return enough trusted price data.",
            dry_run=dry_run,
        )
        return "popular_needs_review"

    signature = build_product_signature(generated)
    if not signature:
        update_popular_status(
            snapshot=snapshot,
            status="needs_review",
            notes="Popular product payload is missing a stable comparison signature.",
            dry_run=dry_run,
        )
        return "popular_needs_review"

    products_collection = database.collection(products_collection_name)
    linked_document_id = safe_string(payload.get("productDocumentId"))
    target_document_id = ""
    target_reference = None

    if linked_document_id:
        linked_reference = products_collection.document(linked_document_id)
        linked_snapshot = linked_reference.get()
        if linked_snapshot.exists:
            target_document_id = linked_snapshot.id
            target_reference = linked_reference

    if target_reference is None:
        matching_product = find_existing_product(existing_products, signature)
        if matching_product is not None:
            target_document_id = safe_string(matching_product.get("documentId"))
            if target_document_id:
                target_reference = products_collection.document(target_document_id)

    write_payload = {
        **generated,
        "is_automated": True,
        "generatedBy": "daily_firestore_price_bot",
        "sourceType": "popular_products",
        "sourcePopularId": snapshot.id,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    result_key = "popular_updated"
    if target_reference is None:
        result_key = "popular_created"
        write_payload["createdAt"] = firestore.SERVER_TIMESTAMP

    if dry_run:
        action = "update" if target_reference is not None else "create"
        print(f"[DRY RUN] would {action} popular product {snapshot.id}: {write_payload}")
        target_document_id = target_document_id or "dry-run"
    else:
        if target_reference is not None:
            target_reference.set(write_payload, merge=True)
        else:
            _, created_reference = products_collection.add(write_payload)
            target_document_id = created_reference.id

    update_popular_status(
        snapshot=snapshot,
        status="synced",
        notes="Popular product synced to products successfully.",
        product_document_id=target_document_id or linked_document_id,
        dry_run=dry_run,
    )

    materialized_product = generated | {"documentId": target_document_id or linked_document_id}
    existing_signature = build_product_signature(materialized_product)
    existing_products[:] = [
        product
        for product in existing_products
        if build_product_signature(product) != existing_signature
    ]
    existing_products.append(materialized_product)
    if existing_signature:
        existing_signatures.add(existing_signature)
    return result_key


def process_search_request(
    *,
    database: firestore.Client,
    snapshot: Any,
    search_client: SearchClient,
    existing_products: List[Dict[str, Any]],
    existing_signatures: set[str],
    dry_run: bool,
    products_collection_name: str,
) -> str:
    payload = snapshot.to_dict() or {}
    status = safe_string(payload.get("status")).lower() or "pending"
    if status not in {"pending", "retry", "needs_review"}:
        return "requests_skipped"

    query = safe_string(payload.get("query"))
    normalized_query = normalize_text(query)
    if len(normalized_query) < 2:
        update_request_status(
            snapshot=snapshot,
            status="invalid",
            notes="Missing query text.",
            dry_run=dry_run,
        )
        return "requests_need_review"

    if any(product_matches_query(product, normalized_query) for product in existing_products):
        update_request_status(
            snapshot=snapshot,
            status="already_available",
            notes="A similar product already exists in the catalog.",
            dry_run=dry_run,
        )
        return "requests_skipped"

    category_id = safe_string(payload.get("categoryId")) or "all"
    category_label = safe_string(payload.get("categoryLabel")) or CATEGORY_LABELS.get(category_id, query)
    generated = build_product_from_search_request(
        search_client=search_client,
        query=query,
        requested_category_id=category_id,
        requested_category_label=category_label,
    )

    if generated is None:
        attempts = safe_int(payload.get("attempts")) + 1
        next_status = "needs_review" if attempts >= 3 else "retry"
        update_request_status(
            snapshot=snapshot,
            status=next_status,
            notes="Not enough priced search results to build a trustworthy comparison.",
            attempts=attempts,
            dry_run=dry_run,
        )
        return "requests_need_review"

    signature = build_product_signature(generated)
    if not signature or signature in existing_signatures:
        update_request_status(
            snapshot=snapshot,
            status="already_available",
            notes="Generated comparison matches an existing catalog card.",
            dry_run=dry_run,
        )
        return "requests_skipped"

    if dry_run:
        print(f"[DRY RUN] would create product for request {snapshot.id}: {generated}")
        product_document_id = "dry-run"
    else:
        _, document_reference = database.collection(products_collection_name).add(
            {
                **generated,
                "is_automated": True,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
                "generatedBy": "daily_firestore_price_bot",
                "sourceRequestId": snapshot.id,
            }
        )
        product_document_id = document_reference.id

    update_request_status(
        snapshot=snapshot,
        status="fulfilled",
        notes="Added to products via daily automation.",
        attempts=safe_int(payload.get("attempts")) + 1,
        fulfilled_product_id=product_document_id,
        dry_run=dry_run,
    )

    existing_products.append(generated | {"documentId": product_document_id})
    existing_signatures.add(signature)
    return "requests_fulfilled"


def sync_top_search_demand_to_popular_products(
    *,
    database: firestore.Client,
    snapshots: Sequence[Any],
    existing_products: Sequence[Dict[str, Any]],
    dry_run: bool,
    popular_products_collection_name: str,
    top_limit: int,
    min_request_count: int,
) -> Dict[str, int]:
    stats = {
        "demand_checked": 0,
        "demand_promoted": 0,
        "demand_updated": 0,
        "demand_skipped": 0,
        "demand_missing_product": 0,
    }
    if top_limit <= 0:
        return stats

    popular_products = database.collection(popular_products_collection_name)

    for snapshot in snapshots[:top_limit]:
        stats["demand_checked"] += 1
        payload = snapshot.to_dict() or {}
        request_count = safe_int(payload.get("requestCount"))
        if request_count < min_request_count:
            stats["demand_skipped"] += 1
            continue

        query = safe_string(payload.get("query"))
        normalized_query = normalize_text(query or safe_string(payload.get("normalizedQuery")))
        if len(normalized_query) < 2:
            stats["demand_skipped"] += 1
            continue

        category_id = safe_string(payload.get("categoryId")) or "all"
        matched_product = find_best_matching_product_for_request(
            existing_products=existing_products,
            normalized_query=normalized_query,
            requested_category_id=category_id,
        )
        if matched_product is None:
            stats["demand_missing_product"] += 1
            continue

        request_document_id = safe_string(snapshot.id)
        popular_document_id = f"search-demand--{request_document_id}"
        popular_reference = popular_products.document(popular_document_id)
        existing_popular_snapshot = popular_reference.get()

        write_payload = build_popular_payload_from_search_demand(
            request_payload=payload,
            matched_product=matched_product,
            request_document_id=request_document_id,
        )
        if not write_payload:
            stats["demand_skipped"] += 1
            continue
        if not existing_popular_snapshot.exists:
            write_payload["createdAt"] = firestore.SERVER_TIMESTAMP

        if dry_run:
            action = "update" if existing_popular_snapshot.exists else "create"
            print(f"[DRY RUN] would {action} high-demand popular product {popular_document_id}: {write_payload}")
        else:
            popular_reference.set(write_payload, merge=True)

        request_updates: Dict[str, Any] = {
            "promotedToPopularAt": firestore.SERVER_TIMESTAMP,
            "popularProductId": popular_document_id,
            "lastMatchedProductId": safe_string(matched_product.get("documentId")),
        }
        if dry_run:
            print(f"[DRY RUN] would update demand request {snapshot.id}: {request_updates}")
        else:
            snapshot.reference.set(request_updates, merge=True)

        if existing_popular_snapshot.exists:
            stats["demand_updated"] += 1
        else:
            stats["demand_promoted"] += 1

    return stats


def build_popular_payload_from_search_demand(
    *,
    request_payload: Dict[str, Any],
    matched_product: Dict[str, Any],
    request_document_id: str,
) -> Dict[str, Any]:
    request_count = safe_int(request_payload.get("requestCount"))
    category_id = safe_string(matched_product.get("categoryId")) or safe_string(request_payload.get("categoryId")) or "all"
    category_label = (
        safe_string(matched_product.get("category"))
        or safe_string(matched_product.get("categoryLabel"))
        or safe_string(request_payload.get("categoryLabel"))
        or CATEGORY_LABELS.get(category_id, category_id)
    )
    query = safe_string(request_payload.get("query"))
    search_terms = [query, category_label, *safe_string_list(matched_product.get("tags"))]
    deduped_search_terms = dedupe_strings(search_terms)

    tags = dedupe_strings(
        [
            TOP_SEARCH_DEMAND_TAG,
            SEARCH_DEMAND_SYNC_TAG,
            category_label,
            *safe_string_list(matched_product.get("tags")),
        ]
    )

    return {
        "active": True,
        "autoGenerated": True,
        "sourceType": "search_demand",
        "sourceSearchRequestId": request_document_id,
        "priority": max(request_count, 1),
        "requestCount": request_count,
        "categoryId": category_id,
        "category": category_label,
        "categoryLabel": category_label,
        "expensiveName": safe_string(matched_product.get("expensiveName")),
        "expensivePrice": safe_float(matched_product.get("expensivePrice")),
        "expensiveImageUrl": safe_string(matched_product.get("expensiveImageUrl")),
        "alternativeName": safe_string(matched_product.get("alternativeName")),
        "alternativePrice": safe_float(matched_product.get("alternativePrice")),
        "alternativeImageUrl": safe_string(matched_product.get("alternativeImageUrl")),
        "buyUrl": safe_string(matched_product.get("buyUrl")),
        "rating": safe_float(matched_product.get("rating")),
        "reviewCount": safe_int(matched_product.get("reviewCount")),
        "productDocumentId": safe_string(matched_product.get("documentId")),
        "searchTerms": deduped_search_terms,
        "tags": tags,
        "notes": f"Auto-promoted from repeated search demand for: {query}".strip(),
        "status": "active",
        "lastDemandedAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "lastPublishedAt": firestore.SERVER_TIMESTAMP,
        **build_optional_popular_fields(matched_product),
    }


def build_optional_popular_fields(product: Dict[str, Any]) -> Dict[str, Any]:
    optional_fields = (
        "fragranceNotes",
        "activeIngredients",
        "localLocationUrl",
        "localLocationLabel",
    )
    return {
        field_name: safe_string(product.get(field_name))
        for field_name in optional_fields
        if safe_string(product.get(field_name))
    }


def build_product_from_search_request(
    *,
    search_client: SearchClient,
    query: str,
    requested_category_id: str,
    requested_category_label: str,
) -> Optional[Dict[str, Any]]:
    hits = search_client.search(
        build_discovery_query(
            query=query,
            requested_category_id=requested_category_id,
            requested_category_label=requested_category_label,
        )
    )
    candidates = [
        candidate
        for candidate in (
            build_candidate_from_hit(
                hit,
                query=query,
                requested_category_id=requested_category_id,
                requested_category_label=requested_category_label,
            )
            for hit in hits
        )
        if candidate is not None
    ]
    candidates = unique_candidates(candidates)
    if len(candidates) < 2:
        return None

    expensive_candidate = max(candidates, key=lambda item: item.price)
    alternative_candidate = min(candidates, key=lambda item: item.price)
    if normalize_text(expensive_candidate.name) == normalize_text(alternative_candidate.name):
        return None

    category_id = expensive_candidate.category_id
    category_label = expensive_candidate.category_label
    tags = [
        category_label,
        query.strip(),
        "\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u062a\u0647 \u0628\u0637\u0644\u0628 \u0645\u0633\u062a\u062e\u062f\u0645",
        expensive_candidate.host_label,
        alternative_candidate.host_label,
    ]
    tags = sync_offer_tags(
        tags,
        expensive_price=expensive_candidate.price,
        alternative_price=alternative_candidate.price,
    )

    payload: Dict[str, Any] = {
        "categoryId": category_id,
        "category": category_label,
        "is_automated": True,
        "expensiveName": expensive_candidate.name,
        "expensivePrice": round(expensive_candidate.price, 2),
        "expensiveImageUrl": "",
        "alternativeName": alternative_candidate.name,
        "alternativePrice": round(alternative_candidate.price, 2),
        "alternativeImageUrl": "",
        "buyUrl": attach_affiliate_tag(alternative_candidate.link),
        "rating": 0.0,
        "reviewCount": 0,
        "tags": tags,
    }

    detail = alternative_candidate.detail or expensive_candidate.detail
    if detail:
        if category_id == "perfumes":
            payload["fragranceNotes"] = detail
        elif category_id in {"cosmetics", "pharmacy"}:
            payload["activeIngredients"] = detail

    return payload


def build_product_from_popular_item(
    *,
    search_client: SearchClient,
    payload: Dict[str, Any],
) -> Optional[Dict[str, Any]]:
    expensive_name = safe_string(payload.get("expensiveName"))
    alternative_name = safe_string(payload.get("alternativeName"))
    if not expensive_name or not alternative_name:
        return None

    raw_search_terms = payload.get("searchTerms")
    if isinstance(raw_search_terms, str):
        search_terms = [part.strip() for part in raw_search_terms.split(",") if part.strip()]
    else:
        search_terms = safe_string_list(raw_search_terms)

    category_id = safe_string(payload.get("categoryId")) or infer_category(
        " ".join([expensive_name, alternative_name, " ".join(search_terms)]),
        requested_category_id="all",
        requested_category_label="",
    )[0]
    category_label = (
        safe_string(payload.get("categoryLabel"))
        or safe_string(payload.get("category"))
        or CATEGORY_LABELS.get(category_id, category_id)
    )

    expensive_hit = choose_best_result(
        search_client.search(build_expensive_query(expensive_name, extra_terms=search_terms)),
        preferred_hosts=EXPENSIVE_HOSTS,
    )
    alternative_hit = choose_best_result(
        search_client.search(build_alternative_query(alternative_name, extra_terms=search_terms)),
        preferred_hosts=ALTERNATIVE_HOSTS,
        require_preferred_host=False,
    )

    expensive_price = extract_price_from_hit(expensive_hit) or safe_float(payload.get("expensivePrice"))
    alternative_price = extract_price_from_hit(alternative_hit) or safe_float(payload.get("alternativePrice"))
    if expensive_price <= 0 or alternative_price <= 0:
        return None

    buy_url = safe_string(payload.get("buyUrl"))
    if alternative_hit is not None and is_supported_store_link(alternative_hit.link):
        buy_url = attach_affiliate_tag(alternative_hit.link)
    elif buy_url:
        buy_url = attach_affiliate_tag(buy_url)

    detail_text = " ".join(
        part
        for part in (
            safe_string(payload.get("notes")),
            safe_string(payload.get("description")),
            safe_string(payload.get("ingredients")),
            safe_string(payload.get("fragranceNotes")),
            " ".join(search_terms),
            expensive_hit.title if expensive_hit else "",
            expensive_hit.snippet if expensive_hit else "",
            alternative_hit.title if alternative_hit else "",
            alternative_hit.snippet if alternative_hit else "",
        )
        if part
    )
    detail = extract_detail(detail_text, category_id)

    tags = [
        category_label,
        "\u0645\u0646\u062a\u062c \u0645\u0634\u0647\u0648\u0631",
        "\u062a\u062d\u062f\u064a\u062b \u064a\u0648\u0645\u064a",
        *search_terms,
    ]
    if expensive_hit is not None:
        tags.append(friendly_host(expensive_hit.host))
    if alternative_hit is not None:
        tags.append(friendly_host(alternative_hit.host))
    tags = sync_offer_tags(
        tags,
        expensive_price=expensive_price,
        alternative_price=alternative_price,
    )

    product: Dict[str, Any] = {
        "categoryId": category_id,
        "category": category_label,
        "is_automated": True,
        "expensiveName": expensive_name,
        "expensivePrice": round(expensive_price, 2),
        "expensiveImageUrl": safe_string(payload.get("expensiveImageUrl")),
        "alternativeName": alternative_name,
        "alternativePrice": round(alternative_price, 2),
        "alternativeImageUrl": safe_string(payload.get("alternativeImageUrl")),
        "buyUrl": buy_url,
        "rating": safe_float(payload.get("rating")),
        "reviewCount": safe_int(payload.get("reviewCount")),
        "tags": tags,
    }

    if detail:
        if category_id == "perfumes":
            product["fragranceNotes"] = detail
        elif category_id in {"cosmetics", "pharmacy"}:
            product["activeIngredients"] = detail

    if category_id == "restaurants":
        local_location_url = safe_string(payload.get("localLocationUrl")) or buy_url
        if local_location_url:
            product["localLocationUrl"] = local_location_url
            product["localLocationLabel"] = safe_string(payload.get("localLocationLabel")) or (
                friendly_host(alternative_hit.host) if alternative_hit is not None else "\u0641\u0631\u0639 \u0645\u062d\u0644\u064a"
            )

    return product


def update_popular_status(
    *,
    snapshot: Any,
    status: str,
    notes: str,
    product_document_id: Optional[str] = None,
    dry_run: bool,
) -> None:
    updates: Dict[str, Any] = {
        "status": status,
        "notes": notes,
        "lastSyncedAt": firestore.SERVER_TIMESTAMP,
    }
    if product_document_id:
        updates["productDocumentId"] = product_document_id

    if dry_run:
        print(f"[DRY RUN] would update popular product {snapshot.id}: {updates}")
        return

    snapshot.reference.set(updates, merge=True)


def update_request_status(
    *,
    snapshot: Any,
    status: str,
    notes: str,
    attempts: Optional[int] = None,
    fulfilled_product_id: Optional[str] = None,
    dry_run: bool,
) -> None:
    updates: Dict[str, Any] = {
        "status": status,
        "notes": notes,
        "lastProcessedAt": firestore.SERVER_TIMESTAMP,
    }
    if attempts is not None:
        updates["attempts"] = attempts
    if fulfilled_product_id:
        updates["fulfilledProductId"] = fulfilled_product_id

    if dry_run:
        print(f"[DRY RUN] would update request {snapshot.id}: {updates}")
        return

    snapshot.reference.set(updates, merge=True)


def build_search_request_rank(snapshot: Any) -> Tuple[int, int]:
    payload = snapshot.to_dict() or {}
    return (
        safe_int(payload.get("requestCount")),
        safe_int(payload.get("attempts")) * -1,
    )


def find_best_matching_product_for_request(
    *,
    existing_products: Sequence[Dict[str, Any]],
    normalized_query: str,
    requested_category_id: str,
) -> Optional[Dict[str, Any]]:
    matches: List[Tuple[Tuple[int, float, int, float], Dict[str, Any]]] = []
    for product in existing_products:
        if not product_matches_query(product, normalized_query):
            continue

        product_category_id = safe_string(product.get("categoryId"))
        category_match = int(
            requested_category_id in {"", "all"} or
            product_category_id == requested_category_id
        )
        rating = safe_float(product.get("rating"))
        review_count = safe_int(product.get("reviewCount"))
        savings_value = max(
            safe_float(product.get("expensivePrice")) - safe_float(product.get("alternativePrice")),
            0.0,
        )
        score = (category_match, rating, review_count, savings_value)
        matches.append((score, product))

    if not matches:
        return None

    matches.sort(key=lambda item: item[0], reverse=True)
    return matches[0][1]


def dedupe_strings(values: Sequence[str]) -> List[str]:
    deduped: List[str] = []
    seen: set[str] = set()
    for value in values:
        text = safe_string(value)
        normalized = normalize_text(text)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        deduped.append(text)
    return deduped


def build_expensive_query(expensive_name: str, *, extra_terms: Sequence[str] = ()) -> str:
    terms = " ".join(term for term in extra_terms if safe_string(term))
    suffix = f" {terms}" if terms else ""
    return f"{expensive_name}{suffix} Saudi Arabia price site:amazon.sa OR site:noon.com"


def build_alternative_query(alternative_name: str, *, extra_terms: Sequence[str] = ()) -> str:
    terms = " ".join(term for term in extra_terms if safe_string(term))
    suffix = f" {terms}" if terms else ""
    return (
        f"{alternative_name}{suffix} Saudi Arabia price "
        "site:noon.com OR site:amazon.sa OR site:nahdionline.com "
        "OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net OR site:mrsool.co"
    )


def build_discovery_query(
    *,
    query: str,
    requested_category_id: str,
    requested_category_label: str,
) -> str:
    category_hint = ""
    if requested_category_id and requested_category_id != "all":
        category_hint = f"{requested_category_label} "

    return (
        f"{query} {category_hint}price ingredients Saudi Arabia "
        "site:amazon.sa OR site:noon.com OR site:nahdionline.com OR site:al-dawaa.com "
        "OR site:hungerstation.com OR site:jahez.net OR site:mrsool.co"
    )


def build_candidate_from_hit(
    hit: SearchHit,
    *,
    query: str,
    requested_category_id: str,
    requested_category_label: str,
) -> Optional[CatalogCandidate]:
    price = extract_price_from_hit(hit)
    if price is None or price <= 0:
        return None

    text_blob = " ".join(part for part in (query, hit.title, hit.snippet) if part)
    category_id, category_label = infer_category(
        text_blob,
        requested_category_id=requested_category_id,
        requested_category_label=requested_category_label,
    )
    return CatalogCandidate(
        name=clean_result_title(hit.title, query),
        price=price,
        link=attach_affiliate_tag(hit.link),
        host_label=friendly_host(hit.host),
        category_id=category_id,
        category_label=category_label,
        detail=extract_detail(text_blob, category_id),
    )


def unique_candidates(candidates: Sequence[CatalogCandidate]) -> List[CatalogCandidate]:
    seen: set[Tuple[str, int]] = set()
    unique: List[CatalogCandidate] = []
    for candidate in candidates:
        marker = (normalize_text(candidate.name), int(round(candidate.price * 100)))
        if marker in seen:
            continue
        seen.add(marker)
        unique.append(candidate)
    return unique


def choose_best_result(
    hits: Sequence[SearchHit],
    *,
    preferred_hosts: Sequence[str],
    require_preferred_host: bool = False,
) -> Optional[SearchHit]:
    best_hit: Optional[SearchHit] = None
    best_score = -1

    for hit in hits:
        host = hit.host
        has_preferred_host = any(preferred_host in host for preferred_host in preferred_hosts)
        if require_preferred_host and not has_preferred_host:
            continue

        score = 0
        if has_preferred_host:
            score += 10
        if extract_price_from_hit(hit) is not None:
            score += 5

        if score > best_score:
            best_hit = hit
            best_score = score

    return best_hit


def clean_result_title(title: str, fallback_query: str) -> str:
    cleaned = re.split(r"\s+[|\-\u2013]\s+", title, maxsplit=1)[0].strip()
    cleaned = re.sub(r"\([^)]*\)", " ", cleaned)
    cleaned = re.sub(r"\[[^\]]*\]", " ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" -|")
    return cleaned or fallback_query.strip()


def extract_price_from_hit(hit: Optional[SearchHit]) -> Optional[float]:
    if hit is None:
        return None
    if getattr(hit, 'price', None) is not None and hit.price > 0:
        return hit.price
    return extract_price(f"{hit.title} {hit.snippet}")


def extract_price(text: str) -> Optional[float]:
    compact = text.replace(",", "")
    for pattern in PRICE_PATTERNS:
        match = pattern.search(compact)
        if match:
            try:
                return float(match.group(1))
            except ValueError:
                return None
    return None


def sync_offer_tags(raw_tags: Any, *, expensive_price: float, alternative_price: float) -> List[str]:
    tags = [
        safe_string(tag)
        for tag in safe_string_list(raw_tags)
        if normalize_text(tag) != normalize_text(ORIGINAL_ON_SALE_TAG)
    ]

    if expensive_price > 0 and alternative_price > 0 and expensive_price <= alternative_price:
        tags.insert(0, ORIGINAL_ON_SALE_TAG)

    deduped: List[str] = []
    seen: set[str] = set()
    for tag in tags:
        normalized = normalize_text(tag)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        deduped.append(tag)
    return deduped


def attach_affiliate_tag(url: str) -> str:
    if not url:
        return ""

    parsed = urlparse(url)
    if not parsed.scheme or not parsed.netloc:
        return url

    query_items = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query_items["tag"] = AFFILIATE_TAG
    return urlunparse(parsed._replace(query=urlencode(query_items)))


def is_supported_store_link(url: str) -> bool:
    host = urlparse(url).netloc.lower()
    return any(supported_host == host or supported_host in host for supported_host in ALTERNATIVE_HOSTS)


def infer_category(
    text: str,
    *,
    requested_category_id: str,
    requested_category_label: str,
) -> Tuple[str, str]:
    if requested_category_id and requested_category_id != "all":
        return requested_category_id, requested_category_label or CATEGORY_LABELS.get(requested_category_id, requested_category_id)

    normalized = normalize_text(text)
    for category_id, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in normalized for keyword in keywords):
            return category_id, CATEGORY_LABELS.get(category_id, requested_category_label or category_id)

    return "all", requested_category_label or CATEGORY_LABELS["all"]


def extract_detail(text: str, category_id: str) -> Optional[str]:
    compact = " ".join(text.split())
    lower_compact = compact.lower()
    if category_id == "perfumes":
        for marker in ("notes", "accords", "\u0646\u0648\u062a\u0629", "\u0631\u0627\u0626\u062d\u0629"):
            if marker in lower_compact:
                return compact[:180]
    if category_id in {"cosmetics", "pharmacy"}:
        for marker in ("ingredients", "active", "\u0645\u0643\u0648\u0646", "\u0645\u0627\u062f\u0629 \u0641\u0639\u0627\u0644\u0629"):
            if marker in lower_compact:
                return compact[:180]
    return None


def product_matches_query(product: Dict[str, Any], normalized_query: str) -> bool:
    searchable = " ".join(
        part
        for part in (
            safe_string(product.get("expensiveName")),
            safe_string(product.get("alternativeName")),
            safe_string(product.get("category")),
            safe_string(product.get("categoryLabel")),
            safe_string(product.get("fragranceNotes")),
            safe_string(product.get("activeIngredients")),
            " ".join(safe_string_list(product.get("tags"))),
        )
        if part
    )
    normalized_searchable = normalize_text(searchable)
    if normalized_query in normalized_searchable:
        return True

    terms = [term for term in normalized_query.split(" ") if term]
    return bool(terms) and all(term in normalized_searchable for term in terms)


def build_product_signature(product: Dict[str, Any]) -> str:
    expensive_name = safe_string(product.get("expensiveName"))
    alternative_name = safe_string(product.get("alternativeName"))
    category = safe_string(product.get("category")) or safe_string(product.get("categoryLabel"))
    if not expensive_name or not alternative_name:
        return ""
    return normalize_text(f"{category}|{expensive_name}|{alternative_name}")


def find_existing_product(
    existing_products: Sequence[Dict[str, Any]],
    signature: str,
) -> Optional[Dict[str, Any]]:
    for product in existing_products:
        if build_product_signature(product) == signature:
            return product
    return None


def prices_different(current_price: float, next_price: float) -> bool:
    return abs(current_price - next_price) >= 0.01


def friendly_host(host: str) -> str:
    normalized = host.lower().replace("www.", "")
    labels = {
        "amazon.sa": "Amazon.sa",
        "noon.com": "Noon",
        "nahdionline.com": "Nahdi",
        "al-dawaa.com": "Al-Dawaa",
        "hungerstation.com": "HungerStation",
        "jahez.net": "Jahez",
        "mrsool.co": "Mrsool",
    }
    return labels.get(normalized, normalized)


def normalize_text(value: str) -> str:
    normalized = value.lower()
    replacements = {
        "\u0623": "\u0627",
        "\u0625": "\u0627",
        "\u0622": "\u0627",
        "\u0629": "\u0647",
        "\u0649": "\u064a",
        "\u0624": "\u0648",
        "\u0626": "\u064a",
    }
    for source, target in replacements.items():
        normalized = normalized.replace(source, target)
    normalized = re.sub(r"[^\w\s]", " ", normalized, flags=re.UNICODE)
    normalized = re.sub(r"\s+", " ", normalized)
    return normalized.strip()


def safe_string(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()


def safe_float(value: Any) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def safe_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def safe_bool(value: Any, *, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    if isinstance(value, (int, float)):
        return bool(value)
    normalized = safe_string(value).lower()
    if normalized in {"true", "1", "yes", "active"}:
        return True
    if normalized in {"false", "0", "no", "inactive"}:
        return False
    return default


def safe_string_list(value: Any) -> List[str]:
    if isinstance(value, (list, tuple)):
        return [safe_string(item) for item in value if safe_string(item)]
    return []


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except requests.HTTPError as error:
        response = error.response
        status = response.status_code if response is not None else "unknown"
        print(f"Search request failed with status {status}: {error}", file=sys.stderr)
        raise SystemExit(1)
    except Exception as error:  # pragma: no cover - operational entrypoint
        print(f"LeastPrice automation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
