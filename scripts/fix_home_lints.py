import re

filepath = r'd:\leastprice\lib\features\home\least_price_home_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove unused imports
content = re.sub(r"import 'package:leastprice/data/models/comparison_search_result\.dart';\n", "", content)
content = re.sub(r"import 'package:leastprice/services/api/serp_api_shopping_search_service\.dart';\n", "", content)
content = re.sub(r"import 'package:leastprice/features/home/plan_picker_section\.dart';\n", "", content)
content = re.sub(r"import 'package:leastprice/features/home/search_suggestions_carousel\.dart';\n", "", content)

# Remove unused _bestCouponForStore
# Wait, let's just find and remove the function
coupon_pattern = r'  Coupon\? _bestCouponForStore\(String storeId\) \{.*?\n  \}\n\n'
content = re.sub(coupon_pattern, '', content, flags=re.DOTALL)

# Remove unused comparisonDataSourceLabel
content = re.sub(r"^\s*final comparisonDataSourceLabel =.*?\n", "", content, flags=re.MULTILINE)

# Fix desiredAccuracy
content = re.sub(r"desiredAccuracy: LocationAccuracy\.high,", "locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),", content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Home page lints fixed.")
