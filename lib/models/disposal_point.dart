class DisposalPoint {
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> categoriesAccepted; // e.g. ["Electronics", "Batteries"]

  DisposalPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.categoriesAccepted,
  });
}