class DisposalPoint {
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> categoriesAccepted;
  final String? source; // <-- add: where the info came from

  DisposalPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.categoriesAccepted,
    this.source, // <-- add
  });
}