

class SmartSearchCandidate {
  const SmartSearchCandidate({
    required this.name,
    required this.price,
    required this.link,
    required this.hostLabel,
    required this.categoryId,
    required this.categoryLabel,
    required this.detail,
  });

  final String name;
  final double price;
  final String link;
  final String hostLabel;
  final String categoryId;
  final String categoryLabel;
  final String? detail;
}
