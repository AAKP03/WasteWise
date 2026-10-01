class WasteCategory {
  final String name;
  final String icon;
  final String disposalType;
  final String guidanceText;
  final String? warningText;

  WasteCategory({
    required this.name,
    required this.icon,
    required this.disposalType,
    required this.guidanceText,
    this.warningText,
  });
}