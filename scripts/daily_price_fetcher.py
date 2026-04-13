#!/usr/bin/env python3
"""
Daily LeastPrice feed generator.

Usage:
  SERPER_API_KEY=... python scripts/daily_price_fetcher.py

Optional env vars:
  AFFILIATE_TAG=myid-21
  INPUT_JSON=assets/data/products.json
  OUTPUT_JSON=generated/leastprice-feed.json
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional


SERPER_ENDPOINT = "https://google.serper.dev/search"
DEFAULT_INPUT = Path("assets/data/products.json")
DEFAULT_OUTPUT = Path("generated/leastprice-feed.json")
AFFILIATE_TAG = os.getenv("AFFILIATE_TAG", "myid-21")
SERPER_API_KEY = os.getenv("SERPER_API_KEY", "").strip()

EXPENSIVE_HOSTS = ["amazon.sa", "noon.com"]
ALTERNATIVE_HOSTS = [
    "amazon.sa",
    "noon.com",
    "nahdionline.com",
    "al-dawaa.com",
    "hungerstation.com",
    "jahez.net",
    "mrsool.co",
]


def main() -> int:
    if not SERPER_API_KEY:
        print("SERPER_API_KEY is required.", file=sys.stderr)
        return 1

    input_path = Path(os.getenv("INPUT_JSON", str(DEFAULT_INPUT)))
    output_path = Path(os.getenv("OUTPUT_JSON", str(DEFAULT_OUTPUT)))

    if not input_path.exists():
        print(f"Input file not found: {input_path}", file=sys.stderr)
        return 1

    catalog = json.loads(input_path.read_text(encoding="utf-8"))
    products = catalog.get("products", [])

    refreshed_products = []
    changed_count = 0

    for product in products:
        refreshed = refresh_product(product)
        refreshed_products.append(refreshed)

        if (
            refreshed.get("expensivePrice") != product.get("expensivePrice")
            or refreshed.get("alternativePrice") != product.get("alternativePrice")
            or refreshed.get("buyUrl") != product.get("buyUrl")
        ):
            changed_count += 1

    catalog["products"] = refreshed_products

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Updated {changed_count} products.")
    print(f"Output written to: {output_path}")
    return 0


def refresh_product(product: Dict[str, Any]) -> Dict[str, Any]:
    product = dict(product)

    expensive_query = build_expensive_query(product)
    alternative_query = build_alternative_query(product)

    expensive_results = serper_search(expensive_query)
    alternative_results = serper_search(alternative_query)

    expensive_match = choose_best_result(expensive_results, EXPENSIVE_HOSTS)
    alternative_match = choose_best_result(
        alternative_results,
        ALTERNATIVE_HOSTS,
        require_preferred_host=True,
    )

    expensive_price = extract_price(expensive_match) or as_float(
        product.get("expensivePrice")
    )
    alternative_price = extract_price(alternative_match) or as_float(
        product.get("alternativePrice")
    )

    if expensive_price > 0:
        product["expensivePrice"] = expensive_price
    if alternative_price > 0:
        product["alternativePrice"] = alternative_price

    if alternative_match and alternative_match.get("link"):
        product["buyUrl"] = attach_affiliate_tag(alternative_match["link"])
    else:
        product["buyUrl"] = attach_affiliate_tag(str(product.get("buyUrl", "")))

    return product


def build_expensive_query(product: Dict[str, Any]) -> str:
    return (
        f"{product.get('expensiveName', '')} "
        "site:amazon.sa OR site:noon.com السعودية سعر"
    )


def build_alternative_query(product: Dict[str, Any]) -> str:
    return (
        f"{product.get('alternativeName', '')} السعودية سعر "
        "site:noon.com OR site:amazon.sa OR site:nahdionline.com "
        "OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net"
    )


def serper_search(query: str) -> List[Dict[str, str]]:
    payload = json.dumps(
        {
            "q": query,
            "gl": "sa",
            "hl": "ar",
            "num": 5,
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        SERPER_ENDPOINT,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-API-KEY": SERPER_API_KEY,
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=25) as response:
            raw = response.read().decode("utf-8")
            data = json.loads(raw)
    except urllib.error.URLError as exc:
        print(f"Search request failed for query: {query}\n{exc}", file=sys.stderr)
        return []

    organic = data.get("organic", [])
    if not isinstance(organic, list):
        return []

    normalized = []
    for item in organic:
        normalized.append(
            {
                "title": str(item.get("title", "")).strip(),
                "link": str(item.get("link", "")).strip(),
                "snippet": str(item.get("snippet", "")).strip(),
            }
        )
    return [item for item in normalized if item["link"]]


def choose_best_result(
    items: List[Dict[str, str]],
    preferred_hosts: List[str],
    require_preferred_host: bool = False,
) -> Optional[Dict[str, str]]:
    best_item: Optional[Dict[str, str]] = None
    best_score = -1

    for item in items:
        link = item.get("link", "")
        parsed = urllib.parse.urlparse(link)
        host = parsed.netloc.lower()
        has_preferred_host = any(domain in host for domain in preferred_hosts)

        if require_preferred_host and not has_preferred_host:
            continue

        score = 0
        if has_preferred_host:
            score += 10
        if extract_price(item) is not None:
            score += 5

        if score > best_score:
            best_item = item
            best_score = score

    return best_item


def extract_price(item: Optional[Dict[str, str]]) -> Optional[float]:
    if not item:
        return None

    text = f"{item.get('title', '')} {item.get('snippet', '')}".replace(",", "")
    patterns = [
        re.compile(r"(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)", re.I),
        re.compile(r"([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)", re.I),
    ]

    for pattern in patterns:
        match = pattern.search(text)
        if match:
            try:
                return float(match.group(1))
            except ValueError:
                return None

    return None


def attach_affiliate_tag(url: str) -> str:
    if not url:
        return url

    parsed = urllib.parse.urlparse(url)
    if not parsed.scheme or not parsed.netloc:
        return url

    query = dict(urllib.parse.parse_qsl(parsed.query, keep_blank_values=True))
    query["tag"] = AFFILIATE_TAG

    return urllib.parse.urlunparse(
        parsed._replace(query=urllib.parse.urlencode(query))
    )


def as_float(value: Any) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


if __name__ == "__main__":
    raise SystemExit(main())
