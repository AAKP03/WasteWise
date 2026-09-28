class WasteCategory {
  final String name;
  final String icon; // emoji or asset path, e.g. "📱"
  final String disposalType; // "Recyclable", "Hazardous", "Donate", "Normal Waste"
  final String guidanceText;
  final String? warningText; // optional, nullable — not every category needs one

  WasteCategory({
    required this.name,
    required this.icon,
    required this.disposalType,
    required this.guidanceText,
    this.warningText,
  });
}