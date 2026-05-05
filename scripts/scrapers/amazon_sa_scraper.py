import re
import requests
from typing import Optional, Dict, Any

try:
    from bs4 import BeautifulSoup
except ImportError:
    BeautifulSoup = None

# Common headers to bypass basic blocks
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
    "Accept-Language": "ar-SA,ar;q=0.9,en-US;q=0.8,en;q=0.7",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
}

def scrape_amazon_sa_product(url: str) -> Optional[Dict[str, Any]]:
    """Scrapes Amazon.sa product page for precise pricing."""
    if BeautifulSoup is None:
        print("BeautifulSoup is not installed. Run: pip install beautifulsoup4")
        return None

    try:
        response = requests.get(url, headers=HEADERS, timeout=10)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Failed to fetch {url}: {e}")
        return None
        
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Try to extract title
    title_element = soup.select_one('#productTitle')
    title = title_element.text.strip() if title_element else None
    
    # Try to extract price
    price_element = soup.select_one('.a-price .a-offscreen')
    if not price_element:
        price_element = soup.select_one('#priceblock_ourprice') or soup.select_one('#priceblock_dealprice')
        
    price_text = price_element.text.strip() if price_element else None
    price_value = None
    
    if price_text:
        # Extract digits: e.g. "ريال 2,599.00" -> 2599.00
        match = re.search(r'([0-9]+[.,]?[0-9]*)', price_text.replace(',', ''))
        if match:
            try:
                price_value = float(match.group(1))
            except ValueError:
                pass

    if not title or not price_value:
        return None

    return {
        "title": title,
        "price": price_value,
        "url": url,
        "store": "Amazon.sa"
    }

if __name__ == "__main__":
    # Test example
    test_url = "https://www.amazon.sa/dp/B0CHX46Q6B" # Example ASIN for iPhone 15
    result = scrape_amazon_sa_product(test_url)
    print(f"Scraping Result: {result}")
