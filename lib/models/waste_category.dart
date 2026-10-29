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

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'disposal_type': disposalType,
        'guidance_text': guidanceText,
        'warning_text': warningText,
      };

  factory WasteCategory.fromMap(Map<String, dynamic> map) => WasteCategory(
        name: map['name'] as String,
        icon: map['icon'] as String,
        disposalType: map['disposal_type'] as String,
        guidanceText: map['guidance_text'] as String,
        warningText: map['warning_text'] as String?,
      );
}