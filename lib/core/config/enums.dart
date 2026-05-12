// App-wide enums to avoid circular dependencies.

enum SearchProviderType {
  serper,
  tavily,
}

enum ComparisonSearchSourceType {
  serpApi,
  scraper,
  amazon,
}

enum ComparisonSearchChannelType {
  marketplace,
  hypermarket,
  delivery,
  pharmacy,
  electronics,
  other,
}

enum HomeCatalogSection {
  offers,
  comparisons,
  coupons,
  plans,
  about,
}
