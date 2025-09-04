class Garage {
  final String id;
  final String name;
  final String userId;

  Garage({required this.id, required this.name, required this.userId});

  factory Garage.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Garage(
      id: documentId,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
    );
  }
}
