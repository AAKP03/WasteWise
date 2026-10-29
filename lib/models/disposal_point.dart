class DisposalPoint {
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> categoriesAccepted;
  final String? source;

  DisposalPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.categoriesAccepted,
    this.source,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'categories_accepted': categoriesAccepted.join(','),
        'source': source,
      };

  factory DisposalPoint.fromMap(Map<String, dynamic> map) => DisposalPoint(
        name: map['name'] as String,
        address: map['address'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        categoriesAccepted: (map['categories_accepted'] as String).split(','),
        source: map['source'] as String?,
      );
}